import { createClient } from "@supabase/supabase-js";
import type { Database } from "./database.types";

/**
 * Create a typed Supabase client.
 * Call this once per app entry point (mobile _layout.tsx, web layout.tsx).
 *
 * @param supabaseUrl  - from EXPO_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
 * @param supabaseKey  - from EXPO_PUBLIC_SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
 */
export function createSupabaseClient(supabaseUrl: string, supabaseKey: string) {
  return createClient<Database>(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false, // false for React Native
    },
  });
}

export type SupabaseClient = ReturnType<typeof createSupabaseClient>;
