/// Configuración de API keys de SerpAPI con nombres amigables.
///
/// Para agregar una key nueva, simplemente agregala a [serpApiKeys].
/// El orden define la prioridad de rotación.
class SerpApiKeyInfo {
  final String key;
  final String name;

  const SerpApiKeyInfo({required this.key, required this.name});

  String get masked => '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
}

const List<SerpApiKeyInfo> serpApiKeys = [
  SerpApiKeyInfo(
    key: '10f70dbeaa2daee16c98dd703b38ba02bbf28211f5fc4d29fe79e62cd511cc70',
    name: 'Viejito',
  ),
  SerpApiKeyInfo(
    key: '18660d4c9f3441928134a19bf57c9f64492cfccd20bd5846b312f7b4ca07e0a0',
    name: 'Yo',
  ),
  SerpApiKeyInfo(
    key: '0bcb655f09b461a5bc25e122ea860d868106109d95601d6bdf58571a5c60a665',
    name: 'Cami',
  ),
  SerpApiKeyInfo(
    key: '7d466e4f19b567dc5313f4b4861fa14bb5a67f18b8f7fb9e7ad8eec8f22c74c0',
    name: 'Juli',
  ),
  SerpApiKeyInfo(
    key: 'a1dd155404b7f2a6e5d7239c84978727539157de2720ac065b86c70a0bd44265',
    name: 'Agus',
  ),
  SerpApiKeyInfo(
    key: 'c0d9b135c4c87551e3b3e07aa8d4830b174d4e975daea676c2b9980df7b0c496',
    name: 'Viejita',
  ),
  SerpApiKeyInfo(
    key: '3606e141d126157bad5f1a277f79c815a22b15de0c0b119586b2115fe9c486a6',
    name: 'Axel',
  ),
  SerpApiKeyInfo(
    key: 'e35bd63fa50b064da7cb37cb948256400d3294233fa72ab1612e71cf6bdceb41',
    name: 'Maru',
  ),
  SerpApiKeyInfo(
    key: 'a5460efbb7042a55e7a1a28ab6d4b0bb6b76ca93a49ea8d88326c8a1e3c3008a',
    name: 'Luquitas',
  ),
  SerpApiKeyInfo(
    key: '6cbc0f25638b5444c59bc6b43030d51a39981a4f2a0f49b697ed84c722e1a659',
    name: 'Coca',
  ),
  SerpApiKeyInfo(
    key: '8b3c382d9c62270ddaa9f65ccdb32775389c2c03062d75b1e9f6d5814b8706d9',
    name: 'Mel',
  ),
  SerpApiKeyInfo(
    key: 'd5a25ac822abb85c5ae03ee184a17ed0a6083f4570f4ea83fa70222f3b1e0ad7',
    name: 'Santi',
  ),
];
