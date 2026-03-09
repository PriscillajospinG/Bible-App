import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

// Screen imports
import HomeScreen from '../screens/HomeScreen';
import BibleReader from '../screens/BibleReader';
import VerseScreen from '../screens/VerseScreen';
import VerseInsight from '../screens/VerseInsight';
import Chatbot from '../screens/Chatbot';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

// Home Stack Navigator
const HomeStackNavigator = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        cardStyle: { backgroundColor: '#fff' },
      }}
    >
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen 
        name="BibleReader" 
        component={BibleReader}
        options={{
          cardStyleInterpolator: ({ current: { progress } }) => ({
            cardStyle: {
              opacity: progress,
            },
          }),
        }}
      />
      <Stack.Screen 
        name="VerseScreen" 
        component={VerseScreen}
        options={{
          cardStyleInterpolator: ({ current: { progress } }) => ({
            cardStyle: {
              opacity: progress,
            },
          }),
        }}
      />
      <Stack.Screen 
        name="VerseInsight" 
        component={VerseInsight}
        options={{
          cardStyleInterpolator: ({ current: { progress } }) => ({
            cardStyle: {
              opacity: progress,
            },
          }),
        }}
      />
    </Stack.Navigator>
  );
};

// Chatbot Stack Navigator
const ChatbotStackNavigator = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        cardStyle: { backgroundColor: '#fff' },
      }}
    >
      <Stack.Screen name="ChatbotScreen" component={Chatbot} />
    </Stack.Navigator>
  );
};

// Root Navigator with Tab Navigation
const AppNavigator = () => {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarActiveTintColor: '#663399',
          tabBarInactiveTintColor: '#999',
          tabBarStyle: {
            backgroundColor: '#fff',
            borderTopColor: '#e0e0e0',
            paddingBottom: 5,
            paddingTop: 8,
          },
          tabBarLabelStyle: {
            fontSize: 12,
            marginTop: -5,
          },
          tabBarIcon: ({ color, size }) => {
            let icon;
            if (route.name === 'HomeTab') {
              icon = '📖';
            } else if (route.name === 'ChatbotTab') {
              icon = '💬';
            }
            return (
              <Text style={{ fontSize: size, marginTop: 5 }}>
                {icon}
              </Text>
            );
          },
        })}
      >
        <Tab.Screen
          name="HomeTab"
          component={HomeStackNavigator}
          options={{
            tabBarLabel: 'Bible',
            title: 'Bible App',
          }}
        />
        <Tab.Screen
          name="ChatbotTab"
          component={ChatbotStackNavigator}
          options={{
            tabBarLabel: 'Chat',
            title: 'AI Chat',
          }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
