
<h1 align="center">
<b>Lazy loading, resizing, cashing and renedring of one thousand photos</b>
   <br><img width="275" height="500" src="https://user-images.githubusercontent.com/16679908/50730413-2c81bd00-111b-11e9-9053-7d1c2e82e615.gif">
</h1>

## The Unsplash API: (https://unsplash.com/developers) is used as the backend for providing a list of one thousand photos.

Although each photo weighs about 4 MB, the general idea is to make the user experience as fluid as possible during the scroll action.

The asynchronous REST request is sent via the NSURLSession framework, 
to fetch the list of photo records. 
The parsing of the resulting JSON list to the local structure is done via the
Decodable protocol. The local structure is an array of photo-records to feed
the table view. Each record retains an URL to download, the author's name, the
width and height of the original photo, and so on. At this point, the table view
knows how many rows it has and the URLs of the images to display. To eliminate
the bottleneck of downloading all images at once, which would be terribly
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
