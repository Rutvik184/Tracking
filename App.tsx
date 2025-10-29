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
      const res = await LocationModule.startLogging(
        'User123',
        'Session45',
        5000,
        0,
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
