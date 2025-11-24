# Odoo Integration Setup Guide

This guide will help you connect your Flutter app to Odoo for managing products, services, events, and inventory.

## Prerequisites

1. **Odoo Instance**: You need a running Odoo instance (version 14+ recommended)
2. **Odoo Access**: Admin or user credentials with appropriate permissions
3. **Database Name**: The name of your Odoo database

## Step 1: Configure Odoo Connection

1. Open the app and navigate to the side menu (hamburger icon)
2. Tap on **"Odoo Configuration"** under Admin & Settings
3. Fill in the following details:
   - **Odoo Base URL**: Your Odoo instance URL (e.g., `https://your-odoo-instance.com`)
   - **Database Name**: Your Odoo database name
   - **Username**: Your Odoo username
   - **Password**: Your Odoo password
4. Tap **"Test & Connect"** to verify the connection

## Step 2: Odoo Model Configuration

### Products (product.product / product.template)

The app expects products to have:
- `name`: Product name
- `description`: Product description
- `list_price`: Selling price
- `categ_id`: Product category
- `image_1920`: Product image (base64 or URL)
- `qty_available`: Available quantity
- `sale_ok`: Must be `True` for products to appear
- `type`: Should be `'product'` for physical products

### Services (product.product / product.template)

For services:
- `name`: Service name
- `description`: Service description
- `list_price`: Service price
- `categ_id`: Service category
- `image_1920`: Service image
- `sale_ok`: Must be `True`
- `type`: Should be `'service'`

### Events (event.event)

For events, ensure you have the **Event Management** module installed:
- `name`: Event name
- `description`: Event description
- `date_begin`: Start date/time
- `date_end`: End date/time
- `address_id`: Event location
- `seats_availability`: Total seats
- `seats_available`: Available seats
- `event_type_id`: Event type/category
- `image_1920`: Event image

## Step 3: Odoo Permissions

Ensure your Odoo user has the following permissions:

1. **Products**: Read access to `product.product` and `product.template`
2. **Services**: Read access to service products
3. **Events**: Read access to `event.event` and `event.registration`
4. **Inventory**: Read access to `stock.quant` for stock information
5. **Sales**: Write access to `sale.order` for creating orders

## Step 4: API Access

Odoo's JSON-RPC API should be enabled by default. If you're having connection issues:

1. Check that your Odoo instance allows JSON-RPC calls
2. Verify the base URL is accessible from your app
3. Check firewall/security settings

## Step 5: Using Odoo Data in Your App

Once connected, the app will automatically:
- Fetch products from Odoo
- Fetch services from Odoo
- Fetch events from Odoo
- Sync inventory/stock information

### Manual Refresh

You can refresh data by:
1. Going to Odoo Configuration
2. The app will automatically refresh on connection
3. Or restart the app to reload data

## Troubleshooting

### Connection Failed
- Verify your Odoo URL is correct and accessible
- Check database name matches exactly
- Verify username and password are correct
- Ensure Odoo instance is running

### No Products/Services Showing
- Check that products/services have `sale_ok = True`
- Verify product type is set correctly (`product` or `service`)
- Check user permissions in Odoo
- Verify category filters if using categories

### Authentication Issues
- Clear app data and reconfigure
- Check Odoo user is active
- Verify database name is correct

## Odoo Customization (Optional)

If you want to add custom fields or models:

1. Create custom fields in Odoo
2. Update `odoo_models.dart` to include new fields
3. Update `odoo_api_service.dart` to fetch new fields
4. Update UI screens to display new data

## Support

For Odoo-specific issues, refer to:
- [Odoo Documentation](https://www.odoo.com/documentation)
- [Odoo API Documentation](https://www.odoo.com/documentation/14.0/developer/reference/backend/orm.html)

For app-specific issues, check the error message in the Odoo Configuration screen.


