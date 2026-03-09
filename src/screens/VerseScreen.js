import React from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
} from 'react-native';
import VerseCard from '../components/VerseCard';

// Placeholder verses
const SAMPLE_VERSES = {
  'Psalm 23': [
    { id: 1, text: 'The Lord is my shepherd, I lack nothing.' },
    { id: 2, text: 'He makes me lie down in green pastures, he leads me beside quiet waters,' },
    { id: 3, text: 'he refreshes my soul. He guides me along the right paths for his name\'s sake.' },
    { id: 4, text: 'Even though I walk through the darkest valley, I will fear no evil, for you are with me; your rod and your staff, they comfort me.' },
    { id: 5, text: 'You prepare a table before me in the presence of my enemies. You anoint my head with oil; my cup overflows.' },
    { id: 6, text: 'Surely your goodness and love will follow me all the days of my life, and I will dwell in the house of the Lord forever.' },
  ],
};

const VerseScreen = ({ navigation, route }) => {
  const { book, chapter } = route.params;
  const key = `${book} ${chapter}`;
  const verses = SAMPLE_VERSES[key] || SAMPLE_VERSES['Psalm 23']; // Default to Psalm 23

  const handleVersePress = (verse) => {
    navigation.navigate('VerseInsight', {
      verse: verse.text,
      book: book,
      chapter: chapter,
      verseNumber: verse.id,
    });
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
        <Text style={styles.headerTitle}>
          {book} {chapter}
        </Text>
        <TouchableOpacity 
          onPress={() => navigation.navigate('Home')}
          style={styles.homeBtn}
        >
          <Text style={styles.homeBtnText}>🏠</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={verses}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <VerseCard
            verseNumber={item.id}
            verseText={item.text}
            onPress={() => handleVersePress(item)}
          />
        )}
        contentContainerStyle={styles.listContent}
      />
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
  listContent: {
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
});

export default VerseScreen;
