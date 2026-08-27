// App.js
import React, { useState } from 'react';
import { View, TextInput, Button, Text, StyleSheet } from 'react-native';
import axios from 'axios';

const App = () => {
  const [input, setInput] = useState('');
  const [advice, setAdvice] = useState('');
  const [loading, setLoading] = useState(false);

  // Handle form submission to fetch AI-generated advice
  const handleSubmit = async () => {
    setLoading(true);
    try {
      const response = await axios.post('http://127.0.0.1:5000/get_forgiveness', {
        input,
      });
      setAdvice(response.data.advice);
    } catch (error) {
      setAdvice('Error fetching advice');
    }
    setLoading(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>AI Forgiveness Recommender</Text>

      {/* Input for user's conflict */}
      <TextInput
        style={styles.input}
        placeholder="Describe your conflict..."
        value={input}
        onChangeText={setInput}
      />

      {/* Button to submit input */}
      <Button title="Get Forgiveness Advice" onPress={handleSubmit} />

      {/* Show loading message */}
      {loading && <Text>Loading...</Text>}

      {/* Show the AI's advice */}
      {advice && <Text style={styles.advice}>{advice}</Text>}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  input: {
    width: '100%',
    padding: 10,
    borderWidth: 1,
    borderRadius: 8,
    marginBottom: 20,
  },
  advice: {
    marginTop: 20,
    fontSize: 18,
    color: 'green',
    textAlign: 'center',
  },
});

export default App;
