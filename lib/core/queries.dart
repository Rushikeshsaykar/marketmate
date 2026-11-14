const String categoriesQuery = r'''
query Categories {
  categoryList {
    id
    name
    children {
      id
      name
      product_count
    }
  }
}
''';

const String productsByCategoryQuery = r'''
query Products($id: String!, $page: Int!, $size: Int!) {
  products(filter: {category_id: {eq: $id}}, currentPage: $page, pageSize: $size) {
    total_count
    page_info {
      current_page
      total_pages
    }
    items {
      id
      name
      sku
      stock_status
      small_image {
        url
        label
      }
      price_range {
        minimum_price {
          regular_price {
            value
            currency
          }
          final_price {
            value
            currency
          }
          discount {
            percent_off
          }
        }
      }
    }
  }
}
''';

const String productDetailQuery = r'''
query Product($sku: String!) {
  products(filter: {sku: {eq: $sku}}) {
    items {
      id
      name
      sku
      stock_status
      short_description {
        html
      }
      description {
        html
      }
      image {
        url
        label
      }
      media_gallery {
        url
        label
      }
      price_range {
        minimum_price {
          regular_price {
            value
            currency
          }
          final_price {
            value
            currency
          }
          discount {
            percent_off
          }
        }
      }
      categories {
        id
        name
      }
    }
  }
}
''';
