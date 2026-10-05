-- =============================================================================
-- spending_summary(): agregados de gasto del usuario autenticado para el
-- asistente con LLM.
--
-- Privacidad por diseño: devuelve SOLO totales por categoría y del período.
-- Nunca descripciones, ids, fechas ni montos individuales: los movimientos
-- crudos no salen de la base hacia el proveedor del LLM.
-- security invoker -> RLS aplica (solo datos del dueño del JWT).
-- =============================================================================

create or replace function public.spending_summary(p_days int default 30)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with params as (
    select least(greatest(coalesce(p_days, 30), 1), 365) as days
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
     where m.created_at >= now() - make_interval(days => (select days from params))
  ),
  cats as (
    select category, round(sum(-amount), 2) as spent, count(*) as n
      from mov
     where amount < 0
     group by category
  )
  select jsonb_build_object(
    'period_days',     (select days from params),
    'currency',        coalesce((select min(currency) from acc), 'USD'),
    'total_balance',   coalesce((select round(sum(balance), 2) from acc), 0),
    'income',          coalesce((select round(sum(amount), 2) from mov where amount > 0), 0),
    'spent',           coalesce((select round(sum(-amount), 2) from mov where amount < 0), 0),
    'movements_count', (select count(*) from mov),
    'by_category',     coalesce(
      (select jsonb_agg(
                jsonb_build_object('category', category, 'spent', spent, 'count', n)
                order by spent desc)
         from cats),
      '[]'::jsonb)
  );
$$;

revoke execute on function public.spending_summary(int) from public, anon;
grant  execute on function public.spending_summary(int) to authenticated;
