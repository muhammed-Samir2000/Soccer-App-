-- Allows an operational day to continue past midnight, for example 15:00 to
-- 02:00 the following calendar day. Equal opening and closing hours remain
-- invalid because they do not describe a usable schedule.

alter table public.venues
  drop constraint if exists venues_check;

alter table public.venues
  drop constraint if exists venues_closing_hour_check;

alter table public.venues
  add constraint venues_closing_hour_check
    check (closing_hour between 0 and 23 and closing_hour <> opening_hour);
