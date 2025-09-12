import { diag, DiagConsoleLogger, DiagLogLevel } from '@opentelemetry/api'
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG)
import { defaultResource, resourceFromAttributes } from '@opentelemetry/resources'
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { ZoneContextManager } from '@opentelemetry/context-zone'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web'
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions'

// Define resource and service attributes
const resource = defaultResource().merge(
  resourceFromAttributes({
    'service.name': import.meta.env.VITE_OTEL_SERVICE_NAME ?? 'bmdsalesfe',
    'service.version': '1.0'
  })
)

// Set up the OTLP trace exporter with basic authentication only
const exporter = new OTLPTraceExporter({
  url: import.meta.env.VITE_OTEL_EXPORTER_OTLP_ENDPOINT + '/v1/traces',
  headers: {
    'Authorization': 'Basic ' + btoa(`${import.meta.env.VITE_SIGNOZ_USERNAME}:${import.meta.env.VITE_SIGNOZ_PASSWORD}`)
  }
})

// Set up the span processor
const processor = new BatchSpanProcessor(exporter)

// Create and configure the WebTracerProvider
const provider = new WebTracerProvider({
  resource: resource,
  spanProcessors: [processor]
})

// Register the tracer provider with the context manager
provider.register({
  contextManager: new ZoneContextManager()
})

// Set up automatic instrumentation for web APIs
registerInstrumentations({
  instrumentations: [
    getWebAutoInstrumentations({
      '@opentelemetry/instrumentation-xml-http-request': {
        propagateTraceHeaderCorsUrls: [
          /https:\/\/.*\.quickops\.io/, // Matches any subdomain of quickops.io
        ],
      },
      '@opentelemetry/instrumentation-fetch': {
        propagateTraceHeaderCorsUrls: [
          /https:\/\/.*\.quickops\.io/, // Matches any subdomain of quickops.io
        ],
      },
    }),
  ],
});