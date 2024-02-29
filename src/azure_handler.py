from azure.storage.blob import BlobServiceClient, ContentSettings


class AzureStorage:
    """
    Implementation of an Azure Cloud storage account and container management
    """

    def __init__(self, connection_string):
        self.blob_service_client = BlobServiceClient.from_connection_string(
            connection_string
        )

    def upload(self, container_name, blob_name, data):
        """
        Uploads a blob to the Azure Blob Storage.
        """
        try:
            extension_to_mimetype = {
                ".jpg": "image/jpeg",
                ".jpeg": "image/jpeg",
                ".png": "image/png",
                ".gif": "image/gif",
                ".webp": "image/webp",
                ".mp4": "video/mp4",
            }

            # Create a blob client using the container_name and blob_name
            blob_client = self.blob_service_client.get_blob_client(
                container=container_name, blob=blob_name
            )

            # Determine the content type from the file extension
            file_extension = blob_name[blob_name.rfind(".") :].lower()
            content_type = extension_to_mimetype.get(
                file_extension, "application/octet-stream"
            )

            content_settings = ContentSettings(content_type=content_type)

            # Upload the data
            blob_client.upload_blob(
                data, blob_type="BlockBlob", content_settings=content_settings
            )

            return True, blob_client.url
        except Exception as e:
            return False, str(e)
