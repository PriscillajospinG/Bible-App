import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
} from 'react-native';

const HomeScreen = ({ navigation }) => {
  const [stage, setStage] = useState('question'); // 'question', 'reason', 'suggestion'
  const [selectedReason, setSelectedReason] = useState(null);

  const reasons = [
    { id: 1, label: 'Busy', emoji: '⏰' },
    { id: 2, label: 'Forgot', emoji: '😅' },
    { id: 3, label: 'No time', emoji: '⏱️' },
  ];

  const handleYes = () => {
    navigation.navigate('BibleReader');
  };

  const handleNo = () => {
    setStage('reason');
  };

  const handleReasonSelect = (reason) => {
    setSelectedReason(reason);
    setStage('suggestion');
  };

  const handleStartReading = () => {
    navigation.navigate('BibleReader');
  };

  const handleBack = () => {
    setStage('question');
    setSelectedReason(null);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <View style={styles.content}>
          {/* Header */}
          <Text style={styles.title}>Bible App</Text>

          {/* Stage 1: Initial Question */}
          {stage === 'question' && (
            <>
              <Text style={styles.question}>
                Did you read the Bible today?
              </Text>

              <View style={styles.buttonContainer}>
                <TouchableOpacity
                  style={[styles.button, styles.yesButton]}
                  onPress={handleYes}
                  activeOpacity={0.7}
                >
                  <Text style={styles.buttonText}>Yes</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[styles.button, styles.noButton]}
                  onPress={handleNo}
                  activeOpacity={0.7}
                >
                  <Text style={styles.buttonText}>No</Text>
                </TouchableOpacity>
              </View>
            </>
          )}

          {/* Stage 2: Reason Selection */}
          {stage === 'reason' && (
            <>
              <Text style={styles.question}>
                Why didn't you read today?
              </Text>

              <View style={styles.reasonsContainer}>
                {reasons.map((reason) => (
                  <TouchableOpacity
                    key={reason.id}
                    style={styles.reasonButton}
                    onPress={() => handleReasonSelect(reason.label)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.reasonEmoji}>{reason.emoji}</Text>
                    <Text style={styles.reasonText}>{reason.label}</Text>
                  </TouchableOpacity>
                ))}
              </View>

              <TouchableOpacity
                style={styles.backButtonSmall}
                onPress={handleBack}
              >
                <Text style={styles.backButtonSmallText}>← Back</Text>
              </TouchableOpacity>
            </>
          )}

          {/* Stage 3: Suggestion */}
          {stage === 'suggestion' && (
            <>
              <Text style={styles.reasonMessage}>
                You selected: <Text style={styles.reasonHighlight}>{selectedReason}</Text>
              </Text>

              <View style={styles.suggestionContainer}>
                <Text style={styles.suggestionTitle}>Today's Suggestion</Text>
                
                <Text style={styles.suggestionVerse}>
                  📖 Try reading Psalm 23 today
                </Text>

                <View style={styles.versePreview}>
                  <Text style={styles.verseBible}>
                    "The Lord is my shepherd, I lack nothing.
                  </Text>
                  <Text style={styles.verseBible}>
                    He makes me lie down in green pastures..."
                  </Text>
                </View>

                <TouchableOpacity
                  style={styles.startButton}
                  onPress={handleStartReading}
                  activeOpacity={0.7}
                >
                  <Text style={styles.startButtonText}>Start Reading</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.backButtonSmall}
                  onPress={handleBack}
                >
                  <Text style={styles.backButtonSmallText}>← Back</Text>
                </TouchableOpacity>
              </View>
            </>
          )}

          {/* Chat Button - Always Visible */}
          <TouchableOpacity
            style={styles.chatButton}
            onPress={() => navigation.navigate('Chatbot')}
            activeOpacity={0.7}
          >
            <Text style={styles.chatButtonText}>💬 Ask AI Question</Text>
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
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
    paddingVertical: 30,
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#663399',
    marginBottom: 40,
    textAlign: 'center',
  },
  question: {
    fontSize: 22,
    fontWeight: '600',
    color: '#333',
    marginBottom: 30,
    textAlign: 'center',
    lineHeight: 30,
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 15,
    marginBottom: 30,
    justifyContent: 'center',
  },
  button: {
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 10,
    minWidth: 110,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 3,
  },
  yesButton: {
    backgroundColor: '#4CAF50',
  },
  noButton: {
    backgroundColor: '#FF6B6B',
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  reasonsContainer: {
    width: '100%',
    marginBottom: 25,
    gap: 12,
  },
  reasonButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#ddd',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  reasonEmoji: {
    fontSize: 24,
    marginRight: 12,
    width: 32,
    textAlign: 'center',
  },
  reasonText: {
    flex: 1,
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
  },
  reasonMessage: {
    fontSize: 16,
    color: '#555',
    marginBottom: 20,
    textAlign: 'center',
  },
  reasonHighlight: {
    fontWeight: 'bold',
    color: '#663399',
    fontSize: 18,
  },
  suggestionContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    width: '100%',
    marginBottom: 20,
    borderLeftWidth: 5,
    borderLeftColor: '#4CAF50',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.15,
    shadowRadius: 5,
    elevation: 4,
  },
  suggestionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#663399',
    marginBottom: 12,
  },
  suggestionVerse: {
    fontSize: 16,
    color: '#333',
    marginBottom: 12,
    fontWeight: '600',
  },
  versePreview: {
    backgroundColor: '#f9f9f9',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#663399',
    marginBottom: 15,
  },
  verseBible: {
    fontSize: 14,
    color: '#555',
    lineHeight: 20,
    fontStyle: 'italic',
  },
  startButton: {
    backgroundColor: '#4CAF50',
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 3,
  },
  startButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  backButtonSmall: {
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: '#ccc',
    alignItems: 'center',
  },
  backButtonSmallText: {
    color: '#333',
    fontSize: 14,
    fontWeight: '600',
  },
  chatButton: {
    marginTop: 20,
    paddingVertical: 12,
    paddingHorizontal: 35,
    backgroundColor: '#2196F3',
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 3,
  },
  chatButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});

export default HomeScreen;
