revoke all on public.message_read_receipts from public;
revoke all on public.message_read_receipts from anon;
revoke all on public.message_read_receipts from authenticated;

grant select, insert, update on public.message_read_receipts to authenticated;
