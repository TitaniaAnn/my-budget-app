import { View, Text, StyleSheet } from 'react-native';

export default function AccountsScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Accounts</Text>
      <Text style={styles.subtitle}>Adult & child accounts, credit cards</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#0f172a', padding: 24 },
  title: { fontSize: 28, fontWeight: '700', color: '#f8fafc', marginBottom: 8 },
  subtitle: { fontSize: 15, color: '#64748b', textAlign: 'center' },
});
