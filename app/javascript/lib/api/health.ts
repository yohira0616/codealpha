import { api } from "@/lib/api";
import { healthSchema, type Health } from "@/types/health";

// リソース別 API 層のひな形: fetch は lib/api.ts に任せ、レスポンスを zod で検証して返す
export const getHealth = async (): Promise<Health> =>
  healthSchema.parse(await api.get("/health"));
