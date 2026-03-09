import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  ActivityIndicator,
} from 'react-native';

const VerseInsight = ({ navigation, route }) => {
  const { verse, book, chapter, verseNumber } = route.params;
  const [loading, setLoading] = useState(false);
  const [insight, setInsight] = useState(null);

  const generateInsight = () => {
    setLoading(true);
    // Simulate API call
    setTimeout(() => {
      setInsight(
        'This verse reminds us of God\'s constant presence and care. ' +
        'It emphasizes trust, guidance, and the importance of faith during difficult times. ' +
        'The central message is that we need not fear because we are never alone in our struggles.'
      );
      setLoading(false);
    }, 1500);
  };

  const handleBack = () => {
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={handleBack} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Verse Insight</Text>
        <TouchableOpacity 
          onPress={() => navigation.navigate('Home')}
          style={styles.homeBtn}
        >
          <Text style={styles.homeBtnText}>🏠</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Selected Verse */}
        <View style={styles.verseContainer}>
          <Text style={styles.reference}>
            {book} {chapter}:{verseNumber}
          </Text>
          <Text style={styles.verseText}>{verse}</Text>
        </View>

        {/* AI Insight Section */}
        <View style={styles.insightContainer}>
          <View style={styles.insightHeader}>
            <Text style={styles.insightTitle}>🤖 AI Insight</Text>
            {!insight && (
              <TouchableOpacity onPress={generateInsight} disabled={loading}>
                <Text style={styles.generateBtn}>
                  {loading ? 'Generating...' : 'Generate'}
                </Text>
              </TouchableOpacity>
            )}
          </View>

          {loading && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color="#663399" />
              <Text style={styles.loadingText}>Generating insight...</Text>
            </View>
          )}

          {insight && (
            <>
              <Text style={styles.insightText}>{insight}</Text>
              <TouchableOpacity 
                style={styles.refreshBtn}
                onPress={() => {
                  setInsight(null);
                  generateInsight();
                }}
              >
                <Text style={styles.refreshBtnText}>Generate New Insight</Text>
              </TouchableOpacity>
            </>
          )}

          {!insight && !loading && (
            <Text style={styles.placeholderText}>
              Tap "Generate" to get AI-powered insights about this verse.
            </Text>
          )}
        </View>

        {/* Additional Resources */}
        <View style={styles.resourcesContainer}>
          <Text style={styles.resourcesTitle}>Resources</Text>
          <TouchableOpacity style={styles.resourceItem}>
            <Text style={styles.resourceText}>📚 Commentary</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.resourceItem}>
            <Text style={styles.resourceText}>🔗 Related Verses</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.resourceItem}>
            <Text style={styles.resourceText}>💭 Reflect & Pray</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 12,
    backgroundColor: '#663399',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
  },
  backBtn: {
    padding: 8,
  },
  backBtnText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  homeBtn: {
    padding: 8,
  },
  homeBtnText: {
    fontSize: 20,
  },
  content: {
    flex: 1,
    padding: 15,
  },
  verseContainer: {
    backgroundColor: '#fff',
    borderLeftWidth: 4,
    borderLeftColor: '#663399',
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  reference: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#663399',
    marginBottom: 10,
  },
  verseText: {
    fontSize: 16,
    color: '#333',
    lineHeight: 24,
  },
  insightContainer: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  insightHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  insightTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  generateBtn: {
    color: '#663399',
    fontWeight: '600',
    fontSize: 14,
  },
  loadingContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 20,
  },
  loadingText: {
    marginTop: 10,
    color: '#666',
    fontSize: 14,
  },
  insightText: {
    fontSize: 14,
    color: '#555',
    lineHeight: 22,
    marginBottom: 12,
  },
  placeholderText: {
    fontSize: 14,
    color: '#999',
    fontStyle: 'italic',
  },
  refreshBtn: {
    backgroundColor: '#663399',
    paddingVertical: 10,
    paddingHorizontal: 15,
    borderRadius: 6,
    alignItems: 'center',
    marginTop: 10,
  },
  refreshBtnText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
  resourcesContainer: {
    marginBottom: 20,
  },
  resourcesTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  resourceItem: {
    backgroundColor: '#fff',
    paddingVertical: 12,
    paddingHorizontal: 15,
    borderRadius: 6,
    marginBottom: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#4CAF50',
  },
  resourceText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
});

export default VerseInsight;
