-- =============================================================================
-- Seed de datos de demo
-- =============================================================================
-- Prerrequisito: los 3 usuarios ya existen en Supabase Auth (creados desde el
-- dashboard, NO por SQL):
--   joven@test.com    -> segmento joven   (saldo bajo: dispara "fondo de emergencia")
--   pyme@test.com     -> segmento pyme    (muchas transferencias: acceso rápido + cobros)
--   premium@test.com  -> segmento premium (saldo alto: oferta de inversión)
--
-- Idempotente: se puede ejecutar varias veces; recrea cuentas y movimientos de
-- estos 3 usuarios. Las fechas son relativas a now() para que las reglas de
-- "últimos 30 días" funcionen sin importar cuándo se ejecute.
-- Los saldos NO se escriben a mano: los calcula el trigger de movements.
-- =============================================================================

-- No disparar notificaciones push por los movimientos de demo.
select set_config('app.skip_push', 'on', false);

do $$
declare
  v_joven   uuid;
  v_pyme    uuid;
  v_premium uuid;
  a_joven_ah      uuid;
  a_pyme_cte      uuid;
  a_pyme_ah       uuid;
  a_premium_ah    uuid;
  a_premium_cte   uuid;
begin
  select id into v_joven   from auth.users where email = 'joven@test.com';
  select id into v_pyme    from auth.users where email = 'pyme@test.com';
  select id into v_premium from auth.users where email = 'premium@test.com';

  if v_joven is null or v_pyme is null or v_premium is null then
    raise exception 'Faltan usuarios de prueba en auth.users (joven/pyme/premium@test.com). Créalos en Supabase Auth antes del seed.';
  end if;

  -- ---------------------------------------------------------------------------
  -- Perfiles
  -- ---------------------------------------------------------------------------
  insert into public.profiles (id, full_name, segment) values
    (v_joven,   'Ana Torres',     'joven'),
    (v_pyme,    'Carlos Méndez',  'pyme'),
    (v_premium, 'Lucía Andrade',  'premium')
  on conflict (id) do update
    set full_name = excluded.full_name,
        segment   = excluded.segment;

  -- Limpia datos previos (movimientos caen por cascade)
  delete from public.accounts where user_id in (v_joven, v_pyme, v_premium);

  -- ---------------------------------------------------------------------------
  -- Cuentas (balance inicial 0; el trigger lo ajusta con cada movimiento)
  -- ---------------------------------------------------------------------------
  insert into public.accounts (user_id, type, number_masked)
    values (v_joven, 'ahorros', '****4821') returning id into a_joven_ah;
  insert into public.accounts (user_id, type, number_masked)
    values (v_pyme, 'corriente', '****7310') returning id into a_pyme_cte;
  insert into public.accounts (user_id, type, number_masked)
    values (v_pyme, 'ahorros', '****7322') returning id into a_pyme_ah;
  insert into public.accounts (user_id, type, number_masked)
    values (v_premium, 'ahorros', '****9054') returning id into a_premium_ah;
  insert into public.accounts (user_id, type, number_masked)
    values (v_premium, 'corriente', '****9061') returning id into a_premium_cte;

  -- ---------------------------------------------------------------------------
  -- Movimientos
  -- ---------------------------------------------------------------------------
  insert into public.movements (account_id, amount, description, category, created_at) values
    -- Ana (joven): saldo final 60.81 USD (< 100)
    (a_joven_ah,    250.00, 'Pago freelance diseño web',      'ingreso',         now() - interval '20 days'),
    (a_joven_ah,    -45.30, 'Supermercado Santa María',       'comida',          now() - interval '18 days'),
    (a_joven_ah,    -12.50, 'Recarga tarjeta Metro de Quito', 'transporte',      now() - interval '15 days'),
    (a_joven_ah,    -18.99, 'Suscripción streaming',          'entretenimiento', now() - interval '12 days'),
    (a_joven_ah,    -60.00, 'Zapatos deportivos',             'compras',         now() - interval '8 days'),
    (a_joven_ah,    -22.40, 'Almuerzo con amigos',            'comida',          now() - interval '4 days'),
    (a_joven_ah,    -30.00, 'Transferencia a Mateo (arriendo)','transferencia',  now() - interval '2 days'),

    -- Carlos (pyme): muchas transferencias en 30 días
    (a_pyme_cte,   3200.00, 'Ventas del mes - ferretería',    'ingreso',         now() - interval '27 days'),
    (a_pyme_cte,   -450.00, 'Transferencia proveedor Adelca', 'transferencia',   now() - interval '25 days'),
    (a_pyme_cte,   -320.00, 'Transferencia proveedor Pintuco','transferencia',   now() - interval '21 days'),
    (a_pyme_cte,   1200.00, 'Cobro cliente Constructora Andes','transferencia',  now() - interval '17 days'),
    (a_pyme_cte,   -275.00, 'Pago nómina - Juan Pérez',       'transferencia',   now() - interval '14 days'),
    (a_pyme_cte,   -275.00, 'Pago nómina - María López',      'transferencia',   now() - interval '14 days'),
    (a_pyme_cte,    -85.60, 'Planilla luz eléctrica local',   'servicios',       now() - interval '10 days'),
    (a_pyme_cte,    -42.00, 'Internet fibra local',           'servicios',       now() - interval '9 days'),
    (a_pyme_cte,   -180.00, 'Transferencia proveedor Ideal',  'transferencia',   now() - interval '5 days'),
    (a_pyme_cte,    640.00, 'Cobro cliente Ferremax',         'transferencia',   now() - interval '1 day'),
    (a_pyme_ah,    5000.00, 'Depósito fondo de reserva',      'ingreso',         now() - interval '45 days'),
    (a_pyme_ah,   -1000.00, 'Transferencia a cuenta corriente','transferencia',  now() - interval '6 days'),
    (a_pyme_cte,   1000.00, 'Transferencia desde ahorros',    'transferencia',   now() - interval '6 days'),

    -- Lucía (premium): saldo alto
    (a_premium_ah, 12000.00, 'Sueldo septiembre',             'ingreso',         now() - interval '26 days'),
    (a_premium_ah,  8500.00, 'Rendimiento póliza de inversión','ingreso',        now() - interval '19 days'),
    (a_premium_ah, -2500.00, 'Transferencia a cuenta corriente','transferencia', now() - interval '16 days'),
    (a_premium_cte, 2500.00, 'Transferencia desde ahorros',   'transferencia',   now() - interval '16 days'),
    (a_premium_cte, -890.00, 'Pasajes aéreos Quito-Madrid',   'compras',         now() - interval '13 days'),
    (a_premium_cte, -320.00, 'Cena aniversario',              'entretenimiento', now() - interval '11 days'),
    (a_premium_cte, -150.00, 'Consulta médica',               'salud',           now() - interval '7 days'),
    (a_premium_cte, -210.75, 'Supermaxi compras del mes',     'comida',          now() - interval '5 days'),
    (a_premium_cte,  -95.00, 'Combustible',                   'transporte',      now() - interval '3 days'),
    (a_premium_cte,  -64.90, 'Plan celular',                  'servicios',       now() - interval '1 day');

  raise notice 'Seed OK: joven=%, pyme=%, premium=%', v_joven, v_pyme, v_premium;
end;
$$;

-- -----------------------------------------------------------------------------
-- Feature flags
-- -----------------------------------------------------------------------------
insert into public.feature_flags (key, enabled, segment, description) values
  ('marketplace',       true,  null,      'Micro-app externa de beneficios'),
  ('quick_transfer',    true,  null,      'Acceso rápido a transferir en el home'),
  ('collections',       true,  'pyme',    'Cobros para negocios'),
  ('investment_offer',  true,  'premium', 'Oferta de inversión personalizada'),
  ('emergency_fund',    true,  null,      'Banner de fondo de emergencia con saldo bajo'),
  ('ai_assistant',      false, null,      'Asistente financiero con LLM (bonus)')
on conflict (key) do update
  set enabled     = excluded.enabled,
      segment     = excluded.segment,
      description = excluded.description,
      updated_at  = now();
