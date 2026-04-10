const {
  buildPublicUrl,
  rewritePublicUploadUrl,
  rewritePublicUploadUrlsDeep,
} = require('../src/utils/publicUrl');

describe('publicUrl helpers', () => {
  const req = {
    protocol: 'http',
    get(header) {
      if (header === 'host') return 'localhost:8080';
      return undefined;
    },
  };

  beforeEach(() => {
    process.env.PUBLIC_BASE_URL = 'http://68.183.225.40:8080';
  });

  afterEach(() => {
    delete process.env.PUBLIC_BASE_URL;
  });

  it('builds public urls for listing image assets', () => {
    expect(buildPublicUrl(req, '/listing-images/example.jpg')).toBe(
      'http://68.183.225.40:8080/listing-images/example.jpg'
    );
  });

  it('rewrites relative listing image paths to the public base url', () => {
    expect(rewritePublicUploadUrl(req, '/listing-images/example.jpg')).toBe(
      'http://68.183.225.40:8080/listing-images/example.jpg'
    );
  });

  it('rewrites listing image paths inside nested payloads', () => {
    expect(
      rewritePublicUploadUrlsDeep(req, {
        images: ['/listing-images/example.jpg'],
        nested: {
          uploads: ['/uploads/listings/legacy.jpg'],
        },
      })
    ).toEqual({
      images: ['http://68.183.225.40:8080/listing-images/example.jpg'],
      nested: {
        uploads: ['http://68.183.225.40:8080/uploads/listings/legacy.jpg'],
      },
    });
  });
});
