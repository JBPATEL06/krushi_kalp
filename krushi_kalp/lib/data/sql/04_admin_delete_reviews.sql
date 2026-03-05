-- Add policy for Admins to delete any review
create policy "Admins can delete any review."
  on public.reviews for delete
  using ( 
    auth.uid() in (
      select id from public.users where role = 'Admin' 
    ) 
  );
