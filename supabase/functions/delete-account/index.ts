import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.76.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

type SupabaseAdmin = ReturnType<typeof createClient>;

type DeleteTarget = {
  table: string;
  columns: string[];
};

const ignorableErrorCodes = new Set([
  "42P01", // undefined_table
  "42703", // undefined_column
  "PGRST116",
  "PGRST204",
]);

const userDeleteTargets: DeleteTarget[] = [
  { table: "conversation_blocks", columns: ["customer_id", "blocked_by"] },
  { table: "messages", columns: ["customer_id"] },
  { table: "bookings", columns: ["customer_id"] },
  { table: "inspiration_comment_reactions", columns: ["user_id"] },
  { table: "inspiration_reactions", columns: ["user_id"] },
  { table: "inspiration_shares", columns: ["user_id"] },
  { table: "inspiration_comments", columns: ["author_id"] },
  { table: "inspiration_items", columns: ["author_id", "user_id", "created_by"] },
  { table: "reviews", columns: ["reviewer_id", "customer_id", "user_id"] },
  { table: "reports", columns: ["reporter_id", "resolved_by"] },
  { table: "homepage_items", columns: ["created_by", "updated_by"] },
  { table: "ranking_overrides", columns: ["created_by", "updated_by"] },
  { table: "audit_logs", columns: ["actor_id"] },
  { table: "app_settings", columns: ["updated_by"] },
  { table: "stylist_applications", columns: ["submitted_by", "owner_id", "reviewed_by"] },
  { table: "salon_applications", columns: ["submitted_by", "reviewed_by"] },
  { table: "blocked_slots", columns: ["created_by", "owner_id", "stylist_owner_id"] },
  { table: "portfolio_works", columns: ["created_by", "owner_id"] },
  { table: "salon_portfolio_works", columns: ["created_by", "owner_id"] },
  { table: "services", columns: ["created_by", "owner_id"] },
  { table: "salons", columns: ["owner_id", "created_by"] },
  { table: "stylists", columns: ["owner_id"] },
  { table: "admin_users", columns: ["user_id"] },
  { table: "profiles", columns: ["id"] },
];

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function isIgnorableDeleteError(error: { code?: string } | null) {
  return Boolean(error?.code && ignorableErrorCodes.has(error.code));
}

async function deleteMatches(
  admin: SupabaseAdmin,
  target: DeleteTarget,
  userID: string,
) {
  for (const column of target.columns) {
    const { error } = await admin
      .from(target.table)
      .delete()
      .eq(column, userID);

    if (error && !isIgnorableDeleteError(error)) {
      console.warn(`delete ${target.table}.${column} failed`, error);
    }
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: "Server is not configured" }, 500);
  }

  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return json({ error: "Invalid session" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  for (const target of userDeleteTargets) {
    await deleteMatches(admin, target, user.id);
  }

  const { error: deleteUserError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteUserError) {
    return json({ error: deleteUserError.message }, 500);
  }

  return json({ deleted: true });
});
