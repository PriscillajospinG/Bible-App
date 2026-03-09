import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
} from 'react-native';

const HomeScreen = ({ navigation }) => {
  const [showSuggestion, setShowSuggestion] = React.useState(false);

  const handleYes = () => {
    navigation.navigate('BibleReader');
  };

  const handleNo = () => {
    setShowSuggestion(true);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Bible App</Text>
        
        <Text style={styles.question}>
          Did you read the Bible today?
        </Text>

        {!showSuggestion ? (
          <View style={styles.buttonContainer}>
            <TouchableOpacity
              style={[styles.button, styles.yesButton]}
              onPress={handleYes}
            >
              <Text style={styles.buttonText}>Yes</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.noButton]}
              onPress={handleNo}
            >
              <Text style={styles.buttonText}>No</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.suggestionContainer}>
            <Text style={styles.suggestionTitle}>Today's Suggestion</Text>
            <Text style={styles.suggestionText}>
              📖 Read Psalm 23 today
            </Text>
            <Text style={styles.suggestionDesc}>
              "The Lord is my shepherd, I lack nothing..."
            </Text>

            <TouchableOpacity
              style={styles.startButton}
              onPress={() => navigation.navigate('BibleReader')}
            >
              <Text style={styles.buttonText}>Start Reading</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.backButton}
              onPress={() => setShowSuggestion(false)}
            >
              <Text style={styles.backButtonText}>Back</Text>
            </TouchableOpacity>
          </View>
        )}

        <TouchableOpacity
          style={styles.chatButton}
          onPress={() => navigation.navigate('Chatbot')}
        >
          <Text style={styles.chatButtonText}>💬 Ask AI</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#663399',
    marginBottom: 30,
  },
  question: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
    marginBottom: 30,
    textAlign: 'center',
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 15,
    marginBottom: 30,
  },
  button: {
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 8,
    minWidth: 100,
    alignItems: 'center',
  },
  yesButton: {
    backgroundColor: '#4CAF50',
  },
  noButton: {
    backgroundColor: '#FF6B6B',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  suggestionContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    width: '100%',
    alignItems: 'center',
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  suggestionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#663399',
    marginBottom: 10,
  },
  suggestionText: {
    fontSize: 16,
    color: '#333',
    marginBottom: 5,
  },
  suggestionDesc: {
    fontSize: 14,
    color: '#666',
    marginBottom: 20,
    fontStyle: 'italic',
  },
  startButton: {
    backgroundColor: '#4CAF50',
    paddingVertical: 12,
    paddingHorizontal: 40,
    borderRadius: 8,
    marginBottom: 10,
    width: '100%',
    alignItems: 'center',
  },
  backButton: {
    paddingVertical: 10,
    paddingHorizontal: 40,
    borderRadius: 8,
    width: '100%',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ccc',
  },
  backButtonText: {
    color: '#333',
    fontSize: 14,
    fontWeight: '600',
  },
  chatButton: {
    marginTop: 20,
    paddingVertical: 12,
    paddingHorizontal: 30,
    backgroundColor: '#2196F3',
    borderRadius: 8,
  },
  chatButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
});

export default HomeScreen;
