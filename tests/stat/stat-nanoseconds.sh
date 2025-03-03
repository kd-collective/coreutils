#!/bin/sh
# Exercise format strings involving %:X, %:Y, etc.

# Copyright (C) 2010-2025 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
print_ver_ stat

# Set this to avoid problems with weird time zones.
TZ=UTC0
export TZ

# Use a timestamp near the Epoch to avoid trouble with leap seconds.
touch -d '1970-01-01 18:43:33.023456789' k || framework_failure_

ls --full-time | grep 18:43:33.023456789 \
  || skip_ this file system does not support sub-second timestamps

test "$(stat -c       %Y k)" =    67413               || fail=1
test "$(stat -c      %.Y k)" =    67413.023456789     || fail=1
test "$(stat -c     %.1Y k)" =    67413.0             || fail=1
test "$(stat -c     %.3Y k)" =    67413.023           || fail=1
test "$(stat -c     %.6Y k)" =    67413.023456        || fail=1
test "$(stat -c     %.9Y k)" =    67413.023456789     || fail=1
test "$(stat -c   %13.6Y k)" =  ' 67413.023456'       || fail=1
test "$(stat -c  %013.6Y k)" =   067413.023456        || fail=1
test "$(stat -c  %-13.6Y k)" =   '67413.023456 '      || fail=1
test "$(stat -c  %18.10Y k)" = '  67413.0234567890'   || fail=1
test "$(stat -c %I18.10Y k)" = '  67413.0234567890'   || fail=1
test "$(stat -c %018.10Y k)" =  0067413.0234567890    || fail=1
test "$(stat -c %-18.10Y k)" =   '67413.0234567890  ' || fail=1

Exit $fail
