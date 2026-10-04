-- =============================================================================
-- Row Level Security + privilegios
-- =============================================================================
-- Principios:
--   * Deny by default: RLS activado en todas las tablas; anon no ve nada.
--   * Cada usuario solo lee lo suyo vía auth.uid().
--   * El cliente NO escribe saldos ni movimientos: esas escrituras vienen del
--     core bancario (aquí: dashboard / service_role / Edge Functions).
--   * (select auth.uid()) se evalúa una vez por query (initPlan), no por fila.
-- =============================================================================

alter table public.profiles      enable row level security;
alter table public.accounts      enable row level security;
alter table public.movements     enable row level security;
alter table public.feature_flags enable row level security;
alter table public.device_tokens enable row level security;

-- -----------------------------------------------------------------------------
-- Privilegios a nivel de tabla (defensa en profundidad además de RLS)
-- -----------------------------------------------------------------------------
revoke all on public.profiles, public.accounts, public.movements,
              public.feature_flags, public.device_tokens
  from anon, authenticated;

grant select, update (full_name) on public.profiles to authenticated;
grant select on public.accounts      to authenticated;
grant select on public.movements     to authenticated;
grant select on public.feature_flags to authenticated;
grant select, delete on public.device_tokens to authenticated;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
create policy "profiles: owner can read"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "profiles: owner can update name"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- accounts
-- -----------------------------------------------------------------------------
create policy "accounts: owner can read"
  on public.accounts for select to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- movements (propiedad a través de la cuenta)
-- -----------------------------------------------------------------------------
create policy "movements: owner can read"
  on public.movements for select to authenticated
  using (
    exists (
      select 1
        from public.accounts a
       where a.id = movements.account_id
         and a.user_id = (select auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- feature_flags: solo lectura para autenticados
-- -----------------------------------------------------------------------------
create policy "feature_flags: authenticated can read"
  on public.feature_flags for select to authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- device_tokens: alta/actualización vía RPC; el dueño puede leer y borrar
-- -----------------------------------------------------------------------------
create policy "device_tokens: owner can read"
  on public.device_tokens for select to authenticated
  using (user_id = (select auth.uid()));

create policy "device_tokens: owner can delete"
  on public.device_tokens for delete to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- Funciones: solo usuarios autenticados pueden invocar las RPC públicas;
-- las funciones de trigger no son invocables por clientes.
-- -----------------------------------------------------------------------------
revoke execute on function public.register_device_token(text, text) from public, anon;
revoke execute on function public.unregister_device_token(text)     from public, anon;
grant  execute on function public.register_device_token(text, text) to authenticated;
grant  execute on function public.unregister_device_token(text)     to authenticated;

revoke execute on function public.apply_movement_to_balance() from public, anon, authenticated;
revoke execute on function public.handle_new_user()           from public, anon, authenticated;
