import React, { useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  TextInput,
} from 'react-native';

const BOOKS = [
  'Genesis',
  'Exodus',
  'Leviticus',
  'Numbers',
  'Deuteronomy',
  'Joshua',
  'Judges',
  'Ruth',
  '1 Samuel',
  '2 Samuel',
  '1 Kings',
  '2 Kings',
  'Psalms',
  'Proverbs',
  'Ecclesiastes',
  'Isaiah',
  'Jeremiah',
  'Lamentations',
  'Ezekiel',
  'Daniel',
  'Hosea',
  'Joel',
  'Amos',
  'Obadiah',
  'Jonah',
  'Micah',
  'Nahum',
  'Habakkuk',
  'Zephaniah',
  'Haggai',
  'Zechariah',
  'Malachi',
  'Matthew',
  'Mark',
  'Luke',
  'John',
  'Acts',
  'Romans',
  '1 Corinthians',
  '2 Corinthians',
  'Galatians',
  'Ephesians',
  'Philippians',
  'Colossians',
  '1 Thessalonians',
  '2 Thessalonians',
  '1 Timothy',
  '2 Timothy',
  'Titus',
  'Philemon',
  'Hebrews',
  'James',
  '1 Peter',
  '2 Peter',
  '1 John',
  '2 John',
  '3 John',
  'Jude',
  'Revelation',
];

const BibleReader = ({ navigation }) => {
  const [view, setView] = useState('books'); // 'books', 'chapters'
  const [selectedBook, setSelectedBook] = useState(null);
  const [searchText, setSearchText] = useState('');

  const filteredBooks = BOOKS.filter(book =>
    book.toLowerCase().includes(searchText.toLowerCase())
  );

  const chapters = Array.from({ length: 50 }, (_, i) => i + 1); // Placeholder: 50 chapters

  const handleSelectBook = (book) => {
    setSelectedBook(book);
    setView('chapters');
  };

  const handleSelectChapter = (chapter) => {
    navigation.navigate('VerseScreen', {
      book: selectedBook,
      chapter: chapter,
    });
  };

  const handleBack = () => {
    if (view === 'chapters') {
      setView('books');
      setSelectedBook(null);
    }
  };

  const handleGoHome = () => {
    navigation.navigate('Home');
  };

  if (view === 'chapters') {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={handleBack} style={styles.backbtn}>
            <Text style={styles.backBtnText}>← Back</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>{selectedBook}</Text>
          <TouchableOpacity onPress={handleGoHome} style={styles.homeBtn}>
            <Text style={styles.homeBtnText}>🏠</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.chaptersGrid}>
          <FlatList
            data={chapters}
            keyExtractor={(item) => item.toString()}
            numColumns={5}
            columnWrapperStyle={styles.columnWrapper}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.chapterButton}
                onPress={() => handleSelectChapter(item)}
              >
                <Text style={styles.chapterButtonText}>{item}</Text>
              </TouchableOpacity>
            )}
          />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Bible Books</Text>
        <TouchableOpacity onPress={handleGoHome} style={styles.homeBtn}>
          <Text style={styles.homeBtnText}>🏠</Text>
        </TouchableOpacity>
      </View>

      <TextInput
        style={styles.searchInput}
        placeholder="Search books..."
        value={searchText}
        onChangeText={setSearchText}
      />

      <FlatList
        data={filteredBooks}
        keyExtractor={(item) => item}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.bookItem}
            onPress={() => handleSelectBook(item)}
          >
            <Text style={styles.bookItemText}>{item}</Text>
            <Text style={styles.chevron}>›</Text>
          </TouchableOpacity>
        )}
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
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
  },
  homeBtn: {
    padding: 8,
  },
  homeBtnText: {
    fontSize: 20,
  },
  backBtn: {
    padding: 8,
  },
  backBtnText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  searchInput: {
    margin: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#fff',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  bookItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 15,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  bookItemText: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  chevron: {
    fontSize: 20,
    color: '#999',
  },
  chaptersGrid: {
    flex: 1,
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
  columnWrapper: {
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  chapterButton: {
    width: '18%',
    aspectRatio: 1,
    backgroundColor: '#663399',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 8,
  },
  chapterButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
});

export default BibleReader;
