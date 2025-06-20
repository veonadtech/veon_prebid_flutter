abstract class EventListener {
  onAdLoaded(String configId);

  onAdDisplayed(String configId);

  onAdFailed(String configId);

  onAdClicked(String configId);

  onAdUrlClicked(String configId);

  onAdClosed(String configId);
}
