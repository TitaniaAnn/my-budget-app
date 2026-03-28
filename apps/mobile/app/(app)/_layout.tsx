import { Tabs, router } from "expo-router";
import { useEffect } from "react";
import { useAuthStore } from "../../stores/auth";

// Tab bar icons (text-based placeholder — swap for lucide-react-native or expo icons)
function TabIcon({ label, focused }: { label: string; focused: boolean }) {
  return null; // icons added in next phase
}

export default function AppLayout() {
  const { session, isLoading } = useAuthStore();

  useEffect(() => {
    if (!isLoading && !session) {
      router.replace("/(auth)/login");
    }
  }, [session, isLoading]);

  if (!session) return null;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: "#0f172a",
          borderTopColor: "#1e293b",
        },
        tabBarActiveTintColor: "#3b82f6",
        tabBarInactiveTintColor: "#64748b",
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: "500",
        },
      }}
    >
      <Tabs.Screen
        name="dashboard/index"
        options={{ title: "Dashboard" }}
      />
      <Tabs.Screen
        name="accounts/index"
        options={{ title: "Accounts" }}
      />
      <Tabs.Screen
        name="transactions/index"
        options={{ title: "Transactions" }}
      />
      <Tabs.Screen
        name="receipts/index"
        options={{ title: "Receipts" }}
      />
      <Tabs.Screen
        name="budget/index"
        options={{ title: "Budget" }}
      />
      <Tabs.Screen
        name="scenarios/index"
        options={{ title: "Scenarios" }}
      />
      <Tabs.Screen
        name="settings/index"
        options={{ title: "Settings" }}
      />
    </Tabs>
  );
}
