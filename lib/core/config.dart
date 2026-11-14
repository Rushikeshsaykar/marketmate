const baseUrl = 'https://192.168.7.4';
const graphqlUrl = '$baseUrl/graphql';

// Magento may still return image URLs with its old host. Rewrite them:
const oldImageHost = 'https://magento.test';
String fixImageUrl(String url) => url.replaceFirst(oldImageHost, baseUrl);

enum ProviderStatus {
  loading,
  data,
  error,
}
