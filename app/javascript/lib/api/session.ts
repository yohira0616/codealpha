import { z } from "zod";

import { api, ApiError } from "@/lib/api";
import { userSchema, type User } from "@/types/user";

const sessionResponseSchema = z.object({
  user: userSchema,
});

export interface LoginParams {
  email_address: string;
  password: string;
}

// 未ログイン(401)はエラーではなく null として扱い、RequireAuth の分岐に使う
export const getSession = async (): Promise<User | null> => {
  try {
    return sessionResponseSchema.parse(await api.get("/session")).user;
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) return null;
    throw error;
  }
};

export const login = async (params: LoginParams): Promise<User> =>
  sessionResponseSchema.parse(await api.post("/session", params)).user;

export const logout = async (): Promise<void> => api.delete("/session");
