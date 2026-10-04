-- =============================================================================
-- Verificación de RLS y reglas de datos (no deja cambios: ROLLBACK al final)
-- =============================================================================
-- Ejecutar DESPUÉS de migraciones + seed:
--   * Supabase Studio -> SQL Editor: pegar y ejecutar.
--   * o: psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_check.sql
-- Cualquier fallo aborta con "assertion failed" / "RLS FAIL".
-- =============================================================================

begin;

-- Helper: impersonar a un usuario de Auth como lo haría PostgREST con su JWT.
create or replace function pg_temp.login_as(p_email text) returns void
language plpgsql as $$
declare v_id uuid;
begin
  select id into v_id from auth.users where email = p_email;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_id, 'role', 'authenticated')::text,
    true
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- 1. joven solo ve lo suyo
-- -----------------------------------------------------------------------------
select pg_temp.login_as('joven@test.com');
set local role authenticated;

do $$
begin
  assert (select count(*) from public.profiles) = 1, 'RLS FAIL: joven ve perfiles ajenos';
  assert (select count(*) from public.accounts) = 1, 'RLS FAIL: joven ve cuentas ajenas';
  assert (select count(*) from public.movements) = 7, 'RLS FAIL: joven ve movimientos ajenos';
  assert (select balance from public.accounts) = 60.81, 'saldo de joven distinto a 60.81';
  assert (select count(*) from public.feature_flags) >= 6, 'flags no legibles por autenticados';
  assert (select segment from public.customer_snapshot()) = 'joven', 'snapshot segmento';
  assert (select total_balance from public.customer_snapshot()) < 100, 'joven debería tener saldo < 100';
end $$;

-- 1b. el cliente no puede escribir movimientos ni saldos
do $$
begin
  begin
    insert into public.movements (account_id, amount, description)
    select id, 1000, 'hack' from public.accounts limit 1;
    raise exception 'RLS FAIL: cliente pudo insertar movimientos';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.accounts set balance = 1000000;
    raise exception 'RLS FAIL: cliente pudo modificar saldo';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set segment = 'premium';
    raise exception 'RLS FAIL: cliente pudo cambiar su segmento';
  exception when insufficient_privilege then null;
  end;
end $$;

-- 1c. registro de token de dispositivo vía RPC
select public.register_device_token('test-token-0123456789-abcdef', 'android');
do $$
begin
  assert (select count(*) from public.device_tokens) = 1, 'token no registrado';
end $$;

reset role;

-- -----------------------------------------------------------------------------
-- 2. pyme: señales de personalización + reasignación de token
-- -----------------------------------------------------------------------------
select pg_temp.login_as('pyme@test.com');
set local role authenticated;

do $$
declare s record;
begin
  select * into s from public.customer_snapshot();
  assert s.segment = 'pyme', 'snapshot pyme';
  assert s.transfers_30d >= 5, 'pyme debería tener >= 5 transferencias en 30 días';
  assert (select count(*) from public.accounts) = 2, 'pyme debería ver 2 cuentas';
  assert (select count(*) from public.device_tokens) = 0, 'RLS FAIL: pyme ve tokens de joven';
end $$;

-- mismo teléfono, otro usuario: el token se reasigna
select public.register_device_token('test-token-0123456789-abcdef', 'android');
do $$
begin
  assert (select count(*) from public.device_tokens) = 1, 'token no reasignado a pyme';
end $$;

reset role;

-- -----------------------------------------------------------------------------
-- 3. premium: saldo alto
-- -----------------------------------------------------------------------------
select pg_temp.login_as('premium@test.com');
set local role authenticated;
do $$
begin
  assert (select segment from public.customer_snapshot()) = 'premium', 'snapshot premium';
  assert (select total_balance from public.customer_snapshot()) > 10000, 'premium debería tener saldo alto';
end $$;
reset role;

-- -----------------------------------------------------------------------------
-- 4. anon no ve nada
-- -----------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$
begin
  begin
    perform 1 from public.accounts;
    raise exception 'RLS FAIL: anon puede leer cuentas';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- -----------------------------------------------------------------------------
-- 5. Trigger de alta: registro desde la app crea perfil + cuenta
-- -----------------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data)
values (
  '00000000-0000-4000-8000-000000000001',
  'nuevo@test.com',
  '{"full_name":"Nuevo Cliente","segment":"pyme"}'
);
do $$
begin
  assert (select segment from public.profiles
           where id = '00000000-0000-4000-8000-000000000001') = 'pyme',
         'trigger de alta no creó el perfil con su segmento';
  assert (select count(*) from public.accounts
           where user_id = '00000000-0000-4000-8000-000000000001') = 1,
         'trigger de alta no creó la cuenta';
end $$;

-- -----------------------------------------------------------------------------
-- 6. Trigger de saldo: un movimiento nuevo ajusta el saldo
-- -----------------------------------------------------------------------------
do $$
declare v_acc uuid; v_before numeric;
begin
  select a.id, a.balance into v_acc, v_before
    from public.accounts a join auth.users u on u.id = a.user_id
   where u.email = 'joven@test.com';
  insert into public.movements (account_id, amount, description, category)
  values (v_acc, 100, 'Depósito de prueba', 'ingreso');
  assert (select balance from public.accounts where id = v_acc) = v_before + 100,
         'trigger de saldo no actualizó el balance';
end $$;

select 'RLS CHECK OK' as result;

rollback;
