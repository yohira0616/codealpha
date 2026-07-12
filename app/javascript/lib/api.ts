import { z } from "zod";

const API_BASE_URL = "/api";

// Api::BaseController は CSRF 検証をスキップしているが、
// 将来セッション認証 + CSRF 有効化に切り替えても動くようトークンは常に送る
const csrfToken = () =>
  document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") ?? "";

const defaultHeaders = () => ({
  "Content-Type": "application/json",
  "X-CSRF-Token": csrfToken(),
});

export class ApiError extends Error {
  status: number;
  errors: string[];

  constructor(status: number, message: string, errors: string[] = []) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.errors = errors;
  }
}

// Api::BaseController の rescue_from が返す { error: "..." } / { error: [...] } 形式
const errorBodySchema = z.object({
  error: z.union([z.string(), z.array(z.string())]),
});

const parseError = async (response: Response): Promise<ApiError> => {
  const fallback = `API request failed: ${response.status} ${response.statusText}`;
  try {
    const parsed = errorBodySchema.safeParse(await response.json());
    if (parsed.success) {
      const errors = Array.isArray(parsed.data.error)
        ? parsed.data.error
        : [parsed.data.error];
      return new ApiError(response.status, errors.join(", "), errors);
    }
  } catch {
    // ボディが JSON でなければ fallback メッセージを使う
  }
  return new ApiError(response.status, fallback);
};

const request = async <T>(path: string, options: RequestInit = {}): Promise<T> => {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    credentials: "same-origin",
    ...options,
    headers: { ...defaultHeaders(), ...options.headers },
  });

  if (!response.ok) {
    throw await parseError(response);
  }

  // 204 No Content などボディなしレスポンスは undefined を返す
  const text = await response.text();
  return (text ? JSON.parse(text) : undefined) as T;
};

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "POST",
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "PUT",
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, {
      method: "PATCH",
      body: body === undefined ? undefined : JSON.stringify(body),
    }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};
