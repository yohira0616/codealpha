import { z } from "zod";

import { api } from "@/lib/api";
import {
  projectListItemSchema,
  projectSchema,
  type Project,
  type ProjectListItem,
} from "@/types/project";

const projectsResponseSchema = z.object({
  projects: z.array(projectListItemSchema),
});

const projectResponseSchema = z.object({
  project: projectSchema,
});

export interface CreateProjectParams {
  name: string;
  client_name?: string;
  requirement_text?: string;
  daily_rate?: number;
}

export interface UpdateProjectParams {
  name?: string;
  client_name?: string;
  requirement_text?: string;
  daily_rate?: number;
}

export const getProjects = async (): Promise<ProjectListItem[]> =>
  projectsResponseSchema.parse(await api.get("/projects")).projects;

export const getProject = async (id: number): Promise<Project> =>
  projectResponseSchema.parse(await api.get(`/projects/${id}`)).project;

export const createProject = async (
  params: CreateProjectParams
): Promise<Project> =>
  projectResponseSchema.parse(await api.post("/projects", { project: params }))
    .project;

export const updateProject = async (
  id: number,
  params: UpdateProjectParams
): Promise<Project> =>
  projectResponseSchema.parse(
    await api.patch(`/projects/${id}`, { project: params })
  ).project;
