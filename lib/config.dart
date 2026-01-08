// Base URL for your Cloud Run service. Override with
// `--dart-define=CLOUD_RUN_BASE_URL=https://your-service.a.run.app` at build
// time or replace the default here.
const String cloudRunBaseUrl = String.fromEnvironment(
  'CLOUD_RUN_BASE_URL',
  defaultValue: 'https://tablecheckingapp-52196131424.asia-southeast2.run.app',
);

const double defaultTaxRate = 0.06;
