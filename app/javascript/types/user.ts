import { z } from "zod";

// GET /api/session / POST /api/session が返すログインユーザー
export const userSchema = z.object({
  id: z.number(),
  email_address: z.string(),
});

export type User = z.infer<typeof userSchema>;
