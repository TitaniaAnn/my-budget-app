/**
 * This file will be auto-generated and overwritten by:
 *   npx supabase gen types typescript --project-id YOUR_PROJECT_ID > packages/api-client/src/database.types.ts
 *
 * The stub below keeps TypeScript happy until the Supabase project is linked.
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      households: {
        Row: {
          id: string;
          name: string;
          created_by: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          created_by: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["households"]["Insert"]>;
      };
      household_members: {
        Row: {
          id: string;
          household_id: string;
          user_id: string;
          role: "owner" | "partner" | "child";
          display_name: string;
          date_of_birth: string | null;
          avatar_url: string | null;
          invited_by: string | null;
          joined_at: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          user_id: string;
          role?: "owner" | "partner" | "child";
          display_name: string;
          date_of_birth?: string | null;
          avatar_url?: string | null;
          invited_by?: string | null;
          joined_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["household_members"]["Insert"]>;
      };
      accounts: {
        Row: {
          id: string;
          household_id: string;
          owner_user_id: string;
          name: string;
          institution: string | null;
          account_type: string;
          last_four: string | null;
          currency: string;
          current_balance: number;
          credit_limit: number | null;
          is_active: boolean;
          color: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          owner_user_id: string;
          name: string;
          institution?: string | null;
          account_type: string;
          last_four?: string | null;
          currency?: string;
          current_balance?: number;
          credit_limit?: number | null;
          is_active?: boolean;
          color?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["accounts"]["Insert"]>;
      };
      transactions: {
        Row: {
          id: string;
          household_id: string;
          account_id: string;
          amount: number;
          currency: string;
          description: string;
          merchant: string | null;
          category_id: string | null;
          transaction_date: string;
          posted_date: string | null;
          pending: boolean;
          source: string;
          entered_by: string | null;
          receipt_id: string | null;
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          account_id: string;
          amount: number;
          currency?: string;
          description: string;
          merchant?: string | null;
          category_id?: string | null;
          transaction_date: string;
          posted_date?: string | null;
          pending?: boolean;
          source?: string;
          entered_by?: string | null;
          receipt_id?: string | null;
          notes?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["transactions"]["Insert"]>;
      };
      categories: {
        Row: {
          id: string;
          household_id: string | null;
          name: string;
          parent_id: string | null;
          icon: string | null;
          color: string | null;
          is_income: boolean;
          sort_order: number;
        };
        Insert: {
          id?: string;
          household_id?: string | null;
          name: string;
          parent_id?: string | null;
          icon?: string | null;
          color?: string | null;
          is_income?: boolean;
          sort_order?: number;
        };
        Update: Partial<Database["public"]["Tables"]["categories"]["Insert"]>;
      };
      receipts: {
        Row: {
          id: string;
          household_id: string;
          uploaded_by: string;
          storage_path: string;
          thumbnail_path: string | null;
          merchant_name: string | null;
          receipt_date: string | null;
          total_amount: number | null;
          ocr_status: string;
          ocr_raw: Json | null;
          uploaded_at: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          uploaded_by: string;
          storage_path: string;
          thumbnail_path?: string | null;
          merchant_name?: string | null;
          receipt_date?: string | null;
          total_amount?: number | null;
          ocr_status?: string;
          ocr_raw?: Json | null;
          uploaded_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["receipts"]["Insert"]>;
      };
      receipt_line_items: {
        Row: {
          id: string;
          receipt_id: string;
          description: string;
          amount: number;
          quantity: number | null;
          unit_price: number | null;
          category_id: string | null;
          is_tax: boolean;
          is_tip: boolean;
          is_discount: boolean;
          sort_order: number;
        };
        Insert: {
          id?: string;
          receipt_id: string;
          description: string;
          amount: number;
          quantity?: number | null;
          unit_price?: number | null;
          category_id?: string | null;
          is_tax?: boolean;
          is_tip?: boolean;
          is_discount?: boolean;
          sort_order?: number;
        };
        Update: Partial<Database["public"]["Tables"]["receipt_line_items"]["Insert"]>;
      };
      budgets: {
        Row: {
          id: string;
          household_id: string;
          category_id: string;
          amount: number;
          period: string;
          start_date: string;
          end_date: string | null;
          created_by: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          category_id: string;
          amount: number;
          period?: string;
          start_date: string;
          end_date?: string | null;
          created_by: string;
        };
        Update: Partial<Database["public"]["Tables"]["budgets"]["Insert"]>;
      };
      scenarios: {
        Row: {
          id: string;
          household_id: string;
          created_by: string;
          parent_id: string | null;
          name: string;
          description: string | null;
          base_date: string;
          is_baseline: boolean;
          color: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          household_id: string;
          created_by: string;
          parent_id?: string | null;
          name: string;
          description?: string | null;
          base_date: string;
          is_baseline?: boolean;
          color?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database["public"]["Tables"]["scenarios"]["Insert"]>;
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      household_role: "owner" | "partner" | "child";
    };
  };
}
