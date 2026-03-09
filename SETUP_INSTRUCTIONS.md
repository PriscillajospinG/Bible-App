# Bible App - Setup Instructions

## Project Structure

This is a React Native Bible app built with Expo, featuring Bible reading, verse insights, and an AI chatbot.

```
Bible-App/
├── src/
│   ├── screens/
│   │   ├── HomeScreen.js          # Home screen with daily question
│   │   ├── BibleReader.js         # Browse Bible books and chapters
│   │   ├── VerseScreen.js         # Display verses of a chapter
│   │   ├── VerseInsight.js        # Show verse with AI insights
│   │   └── Chatbot.js             # AI chat interface
│   ├── components/
│   │   ├── VerseCard.js           # Reusable verse display component
│   │   └── ChatMessage.js         # Chat message bubble component
│   ├── navigation/
│   │   └── AppNavigator.js        # Navigation setup with tabs
│   └── api/
│       ├── bibleApi.js            # Bible data API calls
│       └── aiApi.js               # AI API calls
├── App.js                          # Main app entry point
├── app.json                        # Expo configuration
├── package.json                    # Dependencies
└── .gitignore
```

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Expo CLI: `npm install -g expo-cli`

## Installation

1. Navigate to the project directory:
   ```bash
   cd Bible-App
   ```

2. Install dependencies:
   ```bash
   npm install
   # or
   yarn install
   ```

## Running the App

### iOS
```bash
npm run ios
# or
expo start --ios
```

### Android
```bash
npm run android
# or
expo start --android
```

### Web
```bash
npm run web
# or
expo start --web
```

### Development
```bash
npm start
# or
expo start
```

Then press:
- `i` for iOS simulator
- `a` for Android emulator
- `w` for web browser

## Features

### 1. **HomeScreen**
- Asks "Did you read the Bible today?"
- Yes → Navigate to Bible Reader
- No → Show daily suggestion (Psalm 23)
- Access to AI Chatbot

### 2. **BibleReader**
- Browse all 66 books of the Bible
- Search functionality
- Select a book → view chapters
- Select chapter → view verses

### 3. **VerseScreen**
- Display all verses in a chapter
- Tap verse to get AI insights
- Clean, readable verse cards

### 4. **VerseInsight**
- Display the selected verse
- Generate AI-powered insights
- View related resources
- Commentary and prayer prompts

### 5. **Chatbot**
- Chat interface with AI
- Ask questions about Bible and faith
- Dynamic responses
- Message history

### 6. **Bottom Tab Navigation**
- Bible tab: Main reading interface
- Chat tab: AI chatbot

## Customization

### Adding Real Bible Data
Replace the placeholder data in `src/api/bibleApi.js` with real API endpoints:
```javascript
const BIBLE_API_BASE_URL = 'https://your-api.com/bible';
```

Popular Bible APIs:
- [api.bible](https://scripture.api.bible/)
- [Bible API](https://bible-api.com/)
- [Father Online API](https://fathersonholyspirit.com/Api)

### Connecting to AI Services
Update `src/api/aiApi.js` to use your AI provider:
```javascript
const AI_API_BASE_URL = 'https://api.openai.com/v1';
```

Popular AI services:
- OpenAI (ChatGPT)
- Google Generative AI
- Hugging Face Inference API
- AWS Bedrock

### Styling
- Colors: Update theme colors throughout component files
- Primary purple: `#663399`
- Success green: `#4CAF50`
- Modify `StyleSheet` in each component file

## Screen Navigation Flow

```
HomeScreen
  ├── Yes → BibleReader
  │   ├── Book List
  │   ├── Chapter Selection
  │   └── VerseScreen
  │       └── VerseInsight
  │           └── (Details & AI Insights)
  ├── No → Suggestion Box
  │   └── Start Reading → BibleReader
  └── Ask AI → Chatbot
```

## Available Scripts

- `npm start` - Start development server
- `npm run ios` - Run on iOS simulator
- `npm run android` - Run on Android emulator
- `npm run web` - Run in web browser

## Next Steps

1. **Connect Real APIs**: Replace placeholder API calls with real endpoints
2. **Add Favorites**: Implement a favorites/bookmarks feature
3. **Enable Offline Mode**: Cache Bible data locally
4. **Add Multiple Versions**: Support different Bible translations
5. **User Accounts**: Implement authentication and user profiles
6. **Notifications**: Add daily reminders for Bible reading
7. **Audio**: Add text-to-speech for verses

## Troubleshooting

### Port Already in Use
```bash
expo start -c
```

### Clear Cache
```bash
expo start --clear
```

### Module Not Found
```bash
npm install
```

### iOS Simulator Issues
```bash
sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
```

## Contributing

Feel free to extend this project with:
- Additional features
- Better UI/UX
- Real data integration
- Error handling improvements
- Performance optimizations

## License

MIT License - Feel free to use this project for personal or commercial use.

## Support

For issues or questions, please refer to:
- [React Native Documentation](https://reactnative.dev/)
- [React Navigation Documentation](https://reactnavigation.org/)
- [Expo Documentation](https://docs.expo.dev/)
