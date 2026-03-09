import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';

const VerseCard = ({ verseNumber, verseText, onPress }) => {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <View style={styles.verseNumberContainer}>
        <Text style={styles.verseNumber}>{verseNumber}</Text>
      </View>
      <View style={styles.verseContent}>
        <Text style={styles.verseText} numberOfLines={3}>
          {verseText}
        </Text>
      </View>
      <Text style={styles.arrow}>›</Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 3,
    elevation: 2,
  },
  verseNumberContainer: {
    backgroundColor: '#663399',
    borderRadius: 20,
    width: 36,
    height: 36,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  verseNumber: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
  },
  verseContent: {
    flex: 1,
    marginRight: 10,
  },
  verseText: {
    fontSize: 14,
    color: '#555',
    lineHeight: 20,
  },
  arrow: {
    fontSize: 24,
    color: '#999',
  },
});

export default VerseCard;
