/* Generate random integers.

   Copyright (C) 2006-2025 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* Written by Paul Eggert.  */

#ifndef RANDINT_H

# define RANDINT_H 1

# include <stdint.h>

# include "randread.h"

/* An unsigned integer type, used for random integers, and its maximum
   value.  */
typedef uintmax_t randint;
# define RANDINT_MAX UINTMAX_MAX

struct randint_source;

void randint_free (struct randint_source *) _GL_ATTRIBUTE_NONNULL ();
int randint_all_free (struct randint_source *) _GL_ATTRIBUTE_NONNULL ();
struct randint_source *randint_new (struct randread_source *)
  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC (randint_free, 1)
  _GL_ATTRIBUTE_NONNULL () _GL_ATTRIBUTE_RETURNS_NONNULL;
struct randint_source *randint_all_new (char const *, size_t)
  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC (randint_all_free, 1);
struct randread_source *randint_get_source (struct randint_source const *)
  _GL_ATTRIBUTE_NONNULL () _GL_ATTRIBUTE_PURE;
randint randint_genmax (struct randint_source *, randint genmax)
  _GL_ATTRIBUTE_NONNULL ();

/* Consume random data from *S to generate a random number in the range
   0 .. CHOICES-1.  CHOICES must be nonzero.  */
static inline randint
randint_choose (struct randint_source *s, randint choices)
{
  return randint_genmax (s, choices - 1);
}

#endif
