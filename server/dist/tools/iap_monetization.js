/**
 * IAP monetization tools - 6 tools for in-app purchase management
 */
import { callGodot } from '../server.js';
import { z, Name } from './shared-types.js';
export function registerIAPMonetizationTools(server, bridge) {
  // 1. get_iap_settings
  server.registerTool(
    'get_iap_settings',
    {
      description: 'Get the current in-app purchase configuration',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_iap_settings'),
  );
  // 2. add_product
  server.registerTool(
    'add_product',
    {
      description: 'Add a new in-app purchase product to the catalog',
      inputSchema: {
        product_id: z.string().min(1).describe("Unique product identifier (e.g. 'com.game.coins_100')"),
        type: z.enum(['consumable', 'non_consumable', 'subscription']).describe('Product type'),
        price: z.string().optional().describe("Price display string (e.g. '$0.99')"),
      },
    },
    async (args) => callGodot(bridge, 'add_product', args),
  );
  // 3. remove_product
  server.registerTool(
    'remove_product',
    {
      description: 'Remove a product from the in-app purchase catalog',
      inputSchema: {
        product_id: Name.describe('Product identifier to remove'),
      },
    },
    async (args) => callGodot(bridge, 'remove_product', args),
  );
  // 4. get_products
  server.registerTool(
    'get_products',
    {
      description: 'Get all registered in-app purchase products with their details and prices',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'get_products'),
  );
  // 5. purchase_product
  server.registerTool(
    'purchase_product',
    {
      description: 'Initiate a purchase for a specific product (test/sandbox mode)',
      inputSchema: {
        product_id: Name.describe('Product identifier to purchase'),
      },
    },
    async (args) => callGodot(bridge, 'purchase_product', args),
  );
  // 6. restore_purchases
  server.registerTool(
    'restore_purchases',
    {
      description: 'Restore previously purchased non-consumable and subscription products',
      inputSchema: {},
    },
    async () => callGodot(bridge, 'restore_purchases'),
  );
}
//# sourceMappingURL=iap_monetization.js.map
