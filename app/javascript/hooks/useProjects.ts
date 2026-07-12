import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createProject,
  getProject,
  getProjects,
  updateProject,
  type CreateProjectParams,
  type UpdateProjectParams,
} from "@/lib/api/projects";

export const useProjects = () =>
  useQuery({
    queryKey: ["projects"],
    queryFn: getProjects,
  });

export const useProject = (id: number) =>
  useQuery({
    queryKey: ["projects", id],
    queryFn: () => getProject(id),
    enabled: Number.isInteger(id),
  });

export const useCreateProject = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (params: CreateProjectParams) => createProject(params),
    onSuccess: (project) => {
      queryClient.setQueryData(["projects", project.id], project);
      void queryClient.invalidateQueries({ queryKey: ["projects"], exact: true });
    },
  });
};

export const useUpdateProject = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, params }: { id: number; params: UpdateProjectParams }) =>
      updateProject(id, params),
    onSuccess: (project) => {
      queryClient.setQueryData(["projects", project.id], project);
      void queryClient.invalidateQueries({ queryKey: ["projects"], exact: true });
    },
  });
};
