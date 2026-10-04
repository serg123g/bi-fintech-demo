-- =============================================================================
-- customer_snapshot(): señales de personalización del usuario autenticado.
-- La consume la Edge Function `home-layout` (con el JWT del usuario), así las
-- reglas de negocio reciben datos ya agregados y respetando RLS.
-- security invoker: corre con los permisos del usuario -> RLS aplica.
-- =============================================================================

create or replace function public.customer_snapshot()
returns table (
  user_id               uuid,
  full_name             text,
  segment               text,
  total_balance         numeric,
  currency              text,
  accounts_count        int,
  movements_30d         int,
  transfers_30d         int,
  spent_30d             numeric,
  top_spend_category    text
)
language sql
stable
security invoker
set search_path = ''
as $$
  with me as (
    select p.id, p.full_name, p.segment
      from public.profiles p
     where p.id = (select auth.uid())
  ),
  acc as (
    select a.id, a.balance, a.currency
      from public.accounts a
     where a.user_id = (select auth.uid())
  ),
  mov as (
    select m.amount, m.category
      from public.movements m
      join acc on acc.id = m.account_id
     where m.created_at >= now() - interval '30 days'
  ),
  top_cat as (
    select category
      from mov
     where amount < 0 and category not in ('transferencia')
     group by category
     order by sum(-amount) desc
     limit 1
  )
  select
    me.id,
    me.full_name,
    me.segment,
    coalesce((select sum(balance) from acc), 0)::numeric,
    coalesce((select min(currency) from acc), 'USD')::text,
    (select count(*) from acc)::int,
    (select count(*) from mov)::int,
    (select count(*) from mov where category = 'transferencia')::int,
    coalesce((select sum(-amount) from mov where amount < 0), 0)::numeric,
    (select category from top_cat)
  from me;
$$;

revoke execute on function public.customer_snapshot() from public, anon;
grant  execute on function public.customer_snapshot() to authenticated;
