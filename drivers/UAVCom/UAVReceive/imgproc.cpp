#include <stdio.h>
#include <list>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

//#define CAPTURE_VIDEO

typedef struct _Circle
{
    cv::Point2f center;
      float radius;
} Circle;

void imgproc(const uint8_t *image, int width, int height)
{
  cv::Mat img(height, width, CV_8UC1, const_cast<uint8_t*>(image), width);
  imshow("Original", img);
  cv::waitKey(1);
  return;

  cv::Mat src = img.clone();
  cv::Mat color_src(height, width, CV_8UC3);
  cvtColor(src, color_src, CV_GRAY2RGB);

  // Image processing starts here
  GaussianBlur(src, src, cv::Size(3,3), 0);
  adaptiveThreshold(src, src, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 5, 3);
  //equalizeHist(src, src);
  // TODO: Can think about using multiple thresholds and choosing one where
  // we can detect a pattern
  //threshold(src, src, 100, 255, cv::THRESH_BINARY_INV);

  imshow("Thresholded", src);

  std::vector<std::vector<cv::Point> > contours;

  findContours(src, contours, CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE);
  //printf("Num contours: %lu\n", contours.size());

  std::vector<double> contour_area, contour_arclength;
  contour_area.resize(contours.size());
  contour_arclength.resize(contours.size());
  std::vector<unsigned int> circle_index;
  for(unsigned int idx = 0; idx < contours.size(); idx++)
  {
    if(contours[idx].size() > 25)
    {
      cv::Mat contour(contours[idx]);
      contour_area[idx] = contourArea(contour);
      if(contour_area[idx] > 50)
      {
        contour_arclength[idx] = arcLength(contour,true);
        float q = 4*M_PI*contour_area[idx] /
            (contour_arclength[idx]*contour_arclength[idx]);
        if(q > 0.8f)
        {
          circle_index.push_back(idx);
          //printf("isoperimetric quotient: %f\n", q);
          //Scalar color( rand()&255, rand()&255, rand()&255 );
          //drawContours(contours_dark, contours, idx, color, 1, 8);
        }
      }
    }
  }
  std::list<Circle> circles;
  for(unsigned int i = 0; i < circle_index.size(); i++)
  {
    Circle c;
    cv::Moments moment = moments(contours[circle_index[i]]);
    float inv_m00 = 1./moment.m00;
    c.center = cv::Point2f(moment.m10*inv_m00, moment.m01*inv_m00);
    c.radius = (sqrtf(contour_area[circle_index[i]]/M_PI) + contour_arclength[circle_index[i]]/(2*M_PI))/2.0f;
    circles.push_back(c);
  }

  // Get the circles with centers close to each other
  std::vector<std::list<Circle> > filtered_circles;
  std::list<Circle>::iterator it = circles.begin();
  unsigned int max_length = 0;
  while(it != circles.end())
  {
    std::list<Circle> c;
    c.push_back(*it);

    cv::Point c1 = it->center;

    std::list<Circle>::iterator it2 = it;
    it2++;
    while(it2 != circles.end())
    {
      cv::Point c2 = it2->center;
      std::list<Circle>::iterator it3 = it2;
      it2++;
      if(hypotf(c2.x - c1.x, c2.y - c1.y) < 10)
      {
        c.push_back(*it3);
        circles.erase(it3);
      }
    }
    unsigned int length_c = c.size();
    if(length_c > 1 && length_c > max_length)
    {
      max_length = length_c;
      filtered_circles.push_back(c);
    }

    it2 = it;
    it++;
    circles.erase(it2);
  }

  if(filtered_circles.size() > 0)
  {
    Circle target_circle;
    target_circle.radius = std::numeric_limits<float>::max();

    for(it = filtered_circles.back().begin(); it != filtered_circles.back().end(); it++)
    {
      //printf("circle: c: %f, %f, r: %f\n", it->center.x, it->center.y, it->radius);
      if(it->radius < target_circle.radius)
      {
        target_circle.radius = it->radius;
        target_circle.center = it->center;
      }
    }
    circle(color_src, cv::Point(target_circle.center.x, target_circle.center.y), target_circle.radius, cv::Scalar(0,0,255), 2);
    printf("target: c: %f, %f, r: %f\n", target_circle.center.x, target_circle.center.y, target_circle.radius);

  }
#if defined(CAPTURE_VIDEO)
  static cv::VideoWriter video_writer("output.mp4", CV_FOURCC('M','J','P','G'), 20, cv::Size(width, height));
  video_writer.write(color_src);
#endif
  imshow("Target", color_src);
  cv::waitKey(1);
}
