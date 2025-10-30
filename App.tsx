/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { useEffect } from 'react';
import {
  NativeModules,
  Platform,
  StatusBar,
  Text,
  TouchableOpacity,
  useColorScheme,
  View,
} from 'react-native';
import Permission, { PERMISSIONS, RESULTS } from 'react-native-permissions';
import { SafeAreaProvider } from 'react-native-safe-area-context';

function App() {
  const isDarkMode = useColorScheme() === 'dark';
  const { LocationModule } = NativeModules;

  const startLocationLogger = async () => {
    const granted = await Permission.request(
      Platform.OS == 'android'
        ? PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION
        : PERMISSIONS.IOS.LOCATION_WHEN_IN_USE,
    );

    if (granted === RESULTS.GRANTED) {
      /** Start Logging
       * param 1: userId
       * param 2: sessionId
       * param 3: locationInterval in ms
       * param 4: auto stop in ms
       * param 5: jwtToken
       */
      const res = await LocationModule.startLogging(
        '123',
        'Session45',
        10000,
        60000,
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzY5NDk3NjQ5LCJpYXQiOjE3NjE3MjE2NDksImp0aSI6ImFjMThkOWE1YzY3NTQ4MTJiMzM3ZWI3OWExODJjMjc0IiwidXNlcl9pZCI6NTk0fQ.yO3cgZy4y9Mggpuzh6VrKAfsdoxvgtohEozkpQWfJ5U',
      );
      console.log(res);
    } else {
      console.warn('Location permission denied');
    }
  };

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <View
        style={{
          flex: 1,
          alignItems: 'center',
          justifyContent: 'center',
          rowGap: 10,
        }}
      >
        <TouchableOpacity
          onPress={() => {
            startLocationLogger();
          }}
        >
          <Text>Start</Text>
        </TouchableOpacity>
        <TouchableOpacity
          onPress={() => {
            LocationModule?.stopLogging();
          }}
        >
          <Text>Stop</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaProvider>
  );
}

export default App;
