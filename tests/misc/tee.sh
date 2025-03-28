#!/bin/sh
# test for basic tee functionality.

# Copyright (C) 2005-2025 Free Software Foundation, Inc.

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
print_ver_ tee

echo line >sample || framework_failure_

# POSIX says: "Processing of at least 13 file operands shall be supported."
for n in 0 1 2 12 13; do
  files=$(seq $n)
  rm -f $files
  tee $files <sample >out || fail=1
  for f in out $files; do
    compare sample $f || fail=1
  done
done

# Ensure tee treats '-' as the name of a file, as mandated by POSIX.
# Between v5.3.0 and v8.23, a '-' argument caused tee to send another
# copy of input to standard output.
tee - <sample >out 2>err || fail=1
compare sample ./- || fail=1
compare sample out || fail=1
compare /dev/null err || fail=1

# Ensure tee exits early if no more writable outputs
if test -w /dev/full && test -c /dev/full; then
  yes | returns_ 1 timeout 10 tee /dev/full 2>err >/dev/full || fail=1
  # Ensure an error for each of the 2 outputs
  # (and no redundant errors for stdout).
  test $(wc -l < err) = 2 || { cat err; fail=1; }


  # Ensure we continue with outputs that are OK
  seq 10000 > multi_read || framework_failure_

  returns_ 1 tee /dev/full out2 2>err >out1 <multi_read || fail=1
  cmp multi_read out1 || fail=1
  cmp multi_read out2 || fail=1
  # Ensure an error for failing output
  test $(wc -l < err) = 1 || { cat err; fail=1; }

  returns_ 1 tee out1 out2 2>err >/dev/full <multi_read || fail=1
  cmp multi_read out1 || fail=1
  cmp multi_read out2 || fail=1
  # Ensure an error for failing output
  test $(wc -l < err) = 1 || { cat err; fail=1; }
fi

case $host_triplet in
  *aix*) echo  'avoiding due to no way to detect closed outputs on AIX' ;;
  *)
# Test iopoll-powered early exit for closed pipes
tee_exited() { sleep $1; test -f tee.exited; }
# Currently this functionality is most useful with
# intermittent input from a terminal, but here we
# use an input pipe that doesn't write anything
# but will exit as soon as tee does, or it times out
retry_delay_ tee_exited .1 7 | # 12.7s (Must be > following timeout)
{ timeout 10 tee -p 2>err && touch tee.exited; } | :
test $(wc -l < err) = 0 || { cat err; fail=1; }
test -f tee.exited || fail=1 ;;
esac

# Test with unwritable files
if ! uid_is_privileged_; then  # root does not get EPERM.
  touch file.ro || framework_failure_
  chmod a-w file.ro || framework_failure_
  returns_ 1 tee -p </dev/null file.ro || fail=1
fi

mkfifo_or_skip_ fifo

# Ensure tee handles nonblocking output correctly
# Terminate any background processes
cleanup_() { kill $pid 2>/dev/null && wait $pid; }
read_fifo_delayed() {
  { sleep .1; timeout 10 dd of=/dev/null status=none; } <fifo
}
read_fifo_delayed & pid=$!
dd count=20 bs=100K if=/dev/zero status=none |
{
  dd count=0 oflag=nonblock status=none
  tee || { cleanup_; touch tee.fail; }
} >fifo
test -f tee.fail && fail=1 || cleanup_

# Ensure tee honors --output-error modes
read_fifo() { timeout 10 dd count=1 if=fifo of=/dev/null status=none & }

# Determine platform sigpipe exit status
read_fifo
yes >fifo
pipe_status=$?

# Default operation is to continue on output errors but exit silently on SIGPIPE
read_fifo
yes | returns_ $pipe_status timeout 10 tee ./e/noent 2>err >fifo || fail=1
test $(wc -l < err) = 1 || { cat err; fail=1; }

# With -p, SIGPIPE is suppressed, exit 0 for EPIPE when all outputs finished
read_fifo
yes | timeout 10 tee -p 2>err >fifo || fail=1
test $(wc -l < err) = 0 || { cat err; fail=1; }

# With --output-error=warn, exit 1 for EPIPE when all outputs finished
read_fifo
yes | returns_ 1 timeout 10 tee --output-error=warn 2>err >fifo || fail=1
test $(wc -l < err) = 1 || { cat err; fail=1; }

# With --output-error=exit, exit 1 immediately for EPIPE
read_fifo
yes | returns_ 1 timeout 10 tee --output-error=exit /dev/null 2>err >fifo \
  || fail=1
test $(wc -l < err) = 1 || { cat err; fail=1; }

# With --output-error=exit, exit 1 immediately on output error
read_fifo
yes | returns_ 1 timeout 10 tee --output-error=exit ./e/noent 2>err >fifo \
  || fail=1
test $(wc -l < err) = 1 || { cat err; fail=1; }

# With --output-error=exit-nopipe, exit 0 for EPIPE
read_fifo
yes | timeout 10 tee --output-error=exit-nopipe 2>err >fifo || fail=1
test $(wc -l < err) = 0 || { cat err; fail=1; }

wait
Exit $fail
