#ifndef INCLUDES_TARANTOOL_BOX_VY_UPSERT_H
#define INCLUDES_TARANTOOL_BOX_VY_UPSERT_H
/*
 * Copyright 2010-2017, Tarantool AUTHORS, please see AUTHORS file.
 *
 * Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY AUTHORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * AUTHORS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stddef.h>
#include <stdbool.h>

#include "vy_entry.h"

#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */

struct key_def;
struct tuple;

/**
 * Apply the UPSERT statement to the REPLACE, UPSERT or DELETE statement.
 * If the second statement is
 * - REPLACE then update operations of the first one will be applied to the
 *   second and a REPLACE statement will be returned;
 *
 * - UPSERT then the new UPSERT will be created with combined operations of both
 *   arguments;
 *
 * - DELETE or NULL then the first one will be turned into REPLACE and returned
 *   as the result;
 *
 * @param new_stmt       An UPSERT statement.
 * @param old_stmt       An REPLACE/DELETE/UPSERT statement or NULL.
 * @param cmp_def        Key definition of an index, with primary parts.
 * @param suppress_error True if ClientErrors must not be written to log.
 *
 * @retval NULL     Memory allocation error.
 * @retval not NULL Success.
 */
struct tuple *
vy_apply_upsert(struct tuple *new_stmt, struct tuple *old_stmt,
		struct key_def *cmp_def, bool suppress_error);

static inline struct vy_entry
vy_entry_apply_upsert(struct vy_entry new_entry, struct vy_entry old_entry,
		      struct key_def *cmp_def, bool suppress_error)
{
	struct vy_entry result;
	result.hint = old_entry.stmt != NULL ? old_entry.hint : new_entry.hint;
	result.stmt = vy_apply_upsert(new_entry.stmt, old_entry.stmt,
				      cmp_def, suppress_error);
	return result.stmt != NULL ? result : vy_entry_none();
}

#if defined(__cplusplus)
} /* extern "C" */
#endif /* defined(__cplusplus) */

#endif /* INCLUDES_TARANTOOL_BOX_VY_UPSERT_H */
