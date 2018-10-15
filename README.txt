Using Alamofire and SwiftyJSON for JSON array serialization and NsOperationQueue
for scheduling of photo downloading, resizing and rendering

The general idea is to make the user experience as seamless as possible.

The Unsplash API: (https://unsplash.com/developers) is used as the backend to
serve the list of one thousand photos with corresponding URLs.
The asynchronous REST request is sent via the Alamofire framework, 
to fetch the list of photo records. 
The response JSON stanza from Unsplash API looks like this: 
[
  {
    "format": "jpeg",
    "width": 5616,
    "height": 3744,
    "filename": "0000_yC-Yzbqy7PY.jpeg",
    "id": 0,
    "author": "Alejandro Escamilla",
    "author_url": "https://unsplash.com/@alejandroescamilla",
    "post_url": "https://unsplash.com/photos/yC-Yzbqy7PY"
  },
]

The parsing of the resulting JSON list to the local structure is done via the
SwiftyJSON framework. The local structure is an array of photo-records to feed
the table view. Each record retains an URL to download, the author's name, the
width and height of the original photo, and so on. At this point, the table view
knows how many rows it has and the URLs of the images to display. To eliminate
the bottleneck of downloading all the images at once, which would be terribly
inefficient, the NSOperationQueue is used to schedule the asynchronous
operations of downloading and resizing. Each resize operation depends on the
download operation, which means resizing is only started when the downloading is
complete. Downloading and resizing are only scheduled for the visible or potentially
visible cells. The soon to be visible cells are deduced from the direction of
scrolling. The operations are added to the queue by the batches. The scheduling
of the operations is interrupted when the user scrolls quickly through the
table, however all operations that already planned will continue to execute
until they complete. Scheduling of operations is resumed when scrolling slows
down. In the completion handler of an operation, the table is displaying the
corresponding cell with the photo, author name, and download and resize status.
The resulting photo is stored in memory cache structure, which is used for quick
access to said photo. In addition, the parameters such as the number of
scheduled operations as well as the scrolling velocity are rendered to the user
interface using KVO-Compliant Properties.
