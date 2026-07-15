import { AdminListSkeleton } from "@/components/admin/table-skeleton";

export default function Loading() {
  return <AdminListSkeleton withSearch={false} columns={5} />;
}
