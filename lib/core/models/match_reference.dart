bool isTestMatchId(String id) => id.startsWith('test:');
String matchCollection(String id) =>
    isTestMatchId(id) ? 'test_matches' : 'matches';
