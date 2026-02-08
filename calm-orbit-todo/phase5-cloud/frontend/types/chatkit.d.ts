/**
 * TypeScript declarations for OpenAI ChatKit Web Component
 * Feature: 007-ai-chatbot-phase3 (ChatKit integration)
 */

declare namespace JSX {
  interface IntrinsicElements {
    'openai-chatkit': React.DetailedHTMLProps<
      React.HTMLAttributes<HTMLElement> & {
        'api-url'?: string;
        'client-secret'?: string;
        ref?: React.Ref<any>;
      },
      HTMLElement
    >;
  }
}

// Extend Window interface for ChatKit custom elements
interface Window {
  customElements: CustomElementRegistry;
}
