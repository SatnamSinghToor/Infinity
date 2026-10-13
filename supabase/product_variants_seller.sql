-- A seller writes the sizes (variants) of their own products.
--
-- The first policy only let a store's owner write, found through
-- products.store_id — but products are tied to their seller by seller_id,
-- and almost none carry a store_id, so a seller could never add a size to
-- their own product. This keeps that route and adds the seller_id one.
drop policy if exists p_variants_write on public.product_variants;

create policy p_variants_write on public.product_variants
  for all
  using (
    public.is_admin()
    or exists (
      select 1 from public.products p
      where p.id = product_variants.product_id
        and (
          p.seller_id = (select auth.uid())
          or exists (
            select 1 from public.stores s
            where s.id = p.store_id and s.owner_id = (select auth.uid())
          )
        )
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.products p
      where p.id = product_variants.product_id
        and (
          p.seller_id = (select auth.uid())
          or exists (
            select 1 from public.stores s
            where s.id = p.store_id and s.owner_id = (select auth.uid())
          )
        )
    )
  );
