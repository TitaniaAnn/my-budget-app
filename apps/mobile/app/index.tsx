import { View, Text } from "react-native";

export default function Index() {
  return (
    <View style={{ flex: 1, justifyContent: "center", alignItems: "center", backgroundColor: "#0f172a" }}>
      <Text style={{ color: "#f8fafc", fontSize: 24, fontWeight: "700" }}>MyBudget</Text>
      <Text style={{ color: "#64748b", fontSize: 14, marginTop: 8 }}>Loading...</Text>
    </View>
  );
}
