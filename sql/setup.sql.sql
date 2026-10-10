-- ICD-10 assistant: table, full-text index, search function and permissions

create table if not exists icd10_codes (
  code text primary key,
  description text not null,
  fts tsvector generated always as (to_tsvector('english', description)) stored
);

create index if not exists icd10_fts_idx on icd10_codes using gin (fts);

-- Strict search first (all words must match); falls back to matching any word
create or replace function search_icd10(q text, lim int default 25)
returns table(code text, description text, score real)
language plpgsql stable as $$
begin
  return query
    select c.code, c.description, ts_rank(c.fts, plainto_tsquery('english', q))
    from icd10_codes c
    where c.fts @@ plainto_tsquery('english', q)
    order by 3 desc
    limit lim;
  if not found then
    return query
      select c.code, c.description,
             ts_rank(c.fts, websearch_to_tsquery('english', replace(trim(q), ' ', ' or ')))
      from icd10_codes c
      where c.fts @@ websearch_to_tsquery('english', replace(trim(q), ' ', ' or '))
      order by 3 desc
      limit lim;
  end if;
end;
$$;

-- Access for the API roles (the table only holds public reference data)
grant usage on schema public to anon, authenticated, service_role;
grant select on public.icd10_codes to anon, authenticated, service_role;
grant execute on function public.search_icd10(text, int) to anon, authenticated, service_role;
alter table public.icd10_codes enable row level security;
drop policy if exists "read icd10" on public.icd10_codes;
create policy "read icd10" on public.icd10_codes for select using (true);
